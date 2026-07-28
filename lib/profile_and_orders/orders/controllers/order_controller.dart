import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/controllers/food_controllers/food_customer_controllers/favorites_offer_controller.dart';
import 'package:food_app/controllers/food_controllers/food_customer_controllers/food_offer_controller.dart';
import 'package:food_app/controllers/mercure_controller.dart';
import 'package:food_app/constants/cosmetic/cosmetic_strings.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_controller.dart';
import 'package:models/models.dart';
import 'package:food_app/profile_and_orders/orders/models/order_item_model.dart';
import 'package:food_app/models/user_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/services/mercure_service.dart';
import 'package:food_app/profile_and_orders/orders/services/order_service.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

/// Handles the user's orders: the order list, a single order's details,
/// and placing a new order.
class OrderController extends GetxController {
  OrderController(this._service);

  final OrderService _service;

  // ───────────────────────── STATE ─────────────────────────

  /// All of the user's orders (for the orders list screen).
  final orders = <OrderModel>[].obs;
  final totalOrders = 0.obs; // Total number of orders (from API).
  final isLoading = false.obs; // True while loading the first page.
  final isLoadingMore = false.obs; // True while fetching a subsequent page.
  final hasMore = true.obs; // False after the last page is loaded.
  int _page = 1;

  /// The order currently open on the details screen.
  final selectedOrder = Rxn<OrderModel>();
  final isDetailLoading = false.obs; // True while loading details.

  /// True while a new order is being submitted.
  final isPlacingOrder = false.obs;

  /// Error text for the UI (empty = no error).
  final errorMessage = ''.obs;

  /// True while showing cached orders from the previous session.
  final isFromCache = false.obs;

  static const _cacheKey = 'customer_orders';

  /// Optional notes the user attaches to an order.
  final RxString notes = ''.obs;

  // ── Filter / search state (customer order list) ──────────────────────────
  // NOTE: no TextEditingController here on purpose — this controller is
  // `fenix: true` and can be disposed/recreated independently of
  // MainNavigationScreen's AppBar, which is where the search field actually
  // lives and stays mounted across every tab switch. MainNavigationScreen
  // owns the TextEditingController and passes it into OrderListScreen; only
  // the reactive text value lives here. (Previously owning it here caused
  // "Once you have called dispose()... it can no longer be used".)
  final searchQuery = ''.obs;
  final sortOrder = CustomerOrderSort.newest.obs;
  final statusFilter = CustomerOrderStatusFilter.all.obs;
  final dateFilter = OrderDateFilter.all.obs;

  /// The authenticated user's API Platform IRI (e.g. "/api/users/12").
  /// Resolved once on init from GET /api/users/me.
  final userIri = ''.obs;

  /// Full user profile — loaded once on init to read [UserModel.isVerified].
  final currentUser = Rxn<UserModel>();

  /// Returns [orders] filtered and sorted by the current reactive state.
  /// Call inside [Obx] so the list rebuilds whenever any filter changes.
  List<OrderModel> get filteredOrders {
    // `/orders` is a shared, market-agnostic endpoint — the raw response
    // spans every market a business partner operates in, so the Food list
    // must filter down to Food-market orders itself or a customer who also
    // has Cosmetic orders would see both mixed together here. Keyed off the
    // order's own category snapshot rather than `businessPartner.markets`
    // (not reliably present on this list response) — see
    // `isCosmeticCategory`'s doc comment. An order with no items or an
    // unrecognized category is treated as Food's (fail open) rather than
    // hidden, since Food is the default/primary market.
    var result = orders
        .where(
          (o) =>
              o.orderItems.isEmpty ||
              !isCosmeticCategory(o.orderItems.first.categorySnapshot),
        )
        .toList();

    // Search by order ID or business name.
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((o) {
        return o.id.toLowerCase().contains(q) ||
            o.businessPartner.businessName.toLowerCase().contains(q);
      }).toList();
    }

    // Status filter.
    final status = statusFilter.value.apiValue;
    if (status != null) {
      result = result.where((o) => o.status.toLowerCase() == status).toList();
    }

    // Date filter.
    if (dateFilter.value != OrderDateFilter.all) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 6));
      result = result.where((o) {
        final d = DateTime.tryParse(o.createdAt);
        if (d == null) return false;
        if (dateFilter.value == OrderDateFilter.today) {
          return !d.isBefore(today);
        }
        return !d.isBefore(weekAgo);
      }).toList();
    }

    // Sort.
    switch (sortOrder.value) {
      case CustomerOrderSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case CustomerOrderSort.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case CustomerOrderSort.priceHighLow:
        result.sort(
          (a, b) => (double.tryParse(b.totalPrice) ?? 0).compareTo(
            double.tryParse(a.totalPrice) ?? 0,
          ),
        );
      case CustomerOrderSort.priceLowHigh:
        result.sort(
          (a, b) => (double.tryParse(a.totalPrice) ?? 0).compareTo(
            double.tryParse(b.totalPrice) ?? 0,
          ),
        );
    }

    return result;
  }

  // ─────────────────── Real-time updates (Mercure) ───────────────────
  static const _mercure = MercureService();
  StreamSubscription? _mercureSub;
  Worker? _mercureTokenWorker;

  @override
  void onInit() {
    super.onInit();
    _initAsync();
    _connectMercure();
  }

  @override
  void onClose() {
    _mercureSub?.cancel();
    _mercureTokenWorker?.dispose();
    super.onClose();
  }

  /// Opens the SSE subscription to this user's own private orders topic
  /// (`users/{id}/orders`, from [MercureController]) and listens for the
  /// credential being refreshed, so this reconnects with a fresh token
  /// automatically. Mirrors [BusinessOrderController]'s
  /// `_connectMercure`/`_subscribeToBusinessOrders` pair — see that class
  /// for why a proactive JWT-exp refresh is used instead of reacting to an
  /// auth-specific disconnect.
  Future<void> _connectMercure() async {
    final mercureCtrl = Get.find<MercureController>();
    await mercureCtrl.ensureLoaded();
    _subscribeToUserOrders(mercureCtrl);

    _mercureTokenWorker?.dispose();
    _mercureTokenWorker = ever(mercureCtrl.tokenRx, (_) {
      _subscribeToUserOrders(mercureCtrl);
    });
  }

  void _subscribeToUserOrders(MercureController mercureCtrl) {
    final token = mercureCtrl.token;
    final topic = mercureCtrl.userOrdersTopic;
    if (token == null || topic == null) {
      // Was previously a silent no-op — impossible to tell "not connected
      // yet" from "will never connect" from the logs alone. Log the full
      // topics array so a missing users/{id}/orders entry (wrong format,
      // backend didn't include it, etc.) is visible instead of guessed at.
      AppLogger.warning(
        'OrderController',
        'Cannot subscribe to the private orders topic yet — '
            'token=${token != null ? "present" : "MISSING"}, '
            'userOrdersTopic=$topic, all topics=${mercureCtrl.topics}',
      );
      return;
    }

    AppLogger.info('OrderController', 'Subscribing to Mercure topic: $topic');
    _mercureSub?.cancel();
    _mercureSub = _mercure.subscribeToUserOrders(
      topic: topic,
      token: token,
      onOrder: (order) {
        AppLogger.info(
          'OrderController',
          'Mercure: order ${order.orderId} → ${order.status} — refreshing',
        );
        refreshAfterOrderChange();
      },
    );
  }

  /// Refreshes both the order list and, if the detail screen is currently
  /// open, the order it's showing — a live status-change event only tells
  /// us "one of your orders changed," and [OrderDetailScreen] reads a
  /// separate [selectedOrder] field that [fetchOrders] never touches, so a
  /// list-only refresh left the detail screen silently stale while the
  /// event genuinely arrived. Doesn't try to match the event's order id
  /// against [selectedOrder] first — the Mercure/FCM payload's id has a
  /// known habit (see [[project_mercure_realtime]]) of being the numeric DB
  /// id rather than the UUID [OrderModel.id] uses everywhere else in this
  /// app, so an id comparison would silently miss real matches. Just always
  /// re-fetch whichever order is open; the extra call is cheap.
  ///
  /// Shared by the Mercure `users/{id}/orders` subscription above and the
  /// `order_status_changed` FCM path in PushNotificationService, so both
  /// transports behave identically instead of each hand-rolling this.
  Future<void> refreshAfterOrderChange() async {
    final openId = selectedOrder.value?.id;
    // Snapshot statuses before fetchOrders() replaces `orders` wholesale, so
    // a pending→cancelled transition can be detected afterwards. Covers the
    // business cancelling/rejecting one of the customer's orders remotely —
    // cancelOrder() already restores stock optimistically for a
    // customer-initiated cancel, but nothing previously told
    // FoodOfferController when the cancellation came from the other side,
    // so the home screen's stock stayed inflated-looking (i.e. stale, not
    // yet credited back) until a manual refresh.
    final previousStatus = {for (final o in orders) o.id: o.status};

    await Future.wait([
      fetchOrders(),
      if (openId != null) fetchOrderById(openId),
    ]);

    if (!Get.isRegistered<FoodOfferController>()) {
      AppLogger.warning(
        'OrderController',
        'refreshAfterOrderChange: FoodOfferController not registered — '
            'skipping stock-restore scan entirely',
      );
      return;
    }
    final foodCtrl = Get.find<FoodOfferController>();
    var restoredAny = false;
    for (final order in orders) {
      // Must have actually seen this order before with a different status —
      // guards against a first-ever fetch (previousStatus still empty, e.g.
      // this event arrived before _initAsync()'s first fetchOrders()
      // finished) mistaking an order that was *already* cancelled days ago
      // for a brand-new transition and double-crediting stock that was
      // never decremented client-side in the first place.
      final previous = previousStatus[order.id];
      if (previous == null) continue;
      if (order.status.toLowerCase() == 'cancelled' &&
          previous.toLowerCase() != 'cancelled') {
        restoredAny = true;
        AppLogger.info(
          'OrderController',
          'refreshAfterOrderChange: order ${order.id} pending→cancelled — '
              'restoring ${order.orderItems.length} item(s)',
        );
        final restoreItems = await _itemsForRestore(order);
        foodCtrl.restoreQuantities(restoreItems);
        if (Get.isRegistered<FavoritesOfferController>()) {
          Get.find<FavoritesOfferController>().restoreQuantities(restoreItems);
        }
        _restoreProductQuantities(restoreItems);
      }
    }
    if (!restoredAny) {
      AppLogger.info(
        'OrderController',
        'refreshAfterOrderChange: no pending→cancelled transition found in '
            '${orders.length} order(s) (snapshot had ${previousStatus.length}) — '
            'if you just cancelled one, either it is not on the fetched page '
            '(pagination) or the status string does not match "cancelled"',
      );
    }
  }

  /// Returns items safe to pass to a stock-restore call.
  ///
  /// [order] here usually comes from the orders *list* endpoint
  /// (`GET /orders?user=...`), which — confirmed via device log on the
  /// business-side equivalent of this exact bug (2026-07-19,
  /// `restoreQuantities: crediting 1 item(s) for offer id(s) [0]`) —
  /// serializes `orderItems[].foodOffer` as `null` rather than an IRI or
  /// embedded object. `OrderItemModel.fromJson` then falls back to
  /// `FoodOfferModel.fromIri('')`, which can't parse anything out of an
  /// empty string and defaults `id` to `0` — so those items can never match
  /// a real offer in `FoodOfferController`'s cached lists, and the credit
  /// silently no-ops. Only the single-order *detail* endpoint
  /// (`GET /orders/{id}`) reliably embeds a real `foodOffer` reference. If
  /// [order]'s items already look valid (defensive — in case this changes
  /// or the caller already has fresh detail data), skip the extra call.
  Future<List<OrderItemModel>> _itemsForRestore(OrderModel order) async {
    if (order.orderItems.every((i) => i.foodOffer.id > 0)) {
      return order.orderItems;
    }
    try {
      final full = await _service.getOrderById(order.id);
      return full.orderItems;
    } catch (e, s) {
      _logError('_itemsForRestore', e, s);
      return order
          .orderItems; // best effort — restoreQuantities will just no-op
    }
  }

  Future<void> _initAsync() async {
    // Show cached orders immediately while network request is in flight.
    final cached = DataCacheService.load(
      _cacheKey,
      (json) => (json as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (cached != null && cached.isNotEmpty) {
      orders.value = cached;
      isFromCache.value = true;
    }

    await Future.wait([fetchUserIri(), _fetchCurrentUser()]);
    await fetchOrders();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _service.fetchCurrentUser();
    if (user != null) {
      currentUser.value = user;
      Get.find<AuthController>().setEmailVerified(user.isVerified);
    }
  }

  Future<bool> fetchUserIri() async {
    // 1. AuthController — in-memory decoded JWT, fastest path.
    final uid = Get.find<AuthController>().userId;
    if (uid.isNotEmpty) {
      userIri.value = '/api/users/$uid';
      return true;
    }

    // 2. KeycloakAuthService — decode JWT from secure storage.
    final token = await Get.find<KeycloakAuthService>().getValidAccessToken();
    if (token != null) {
      final sub = _subFromToken(token);
      if (sub.isNotEmpty) {
        userIri.value = '/api/users/$sub';
        return true;
      }
    }

    // 3. API fallback.
    try {
      userIri.value = await _service.fetchMyUserIri();
      return true;
    } catch (e, s) {
      _logError('fetchUserIri', e, s);
      return false;
    }
  }

  /// Decodes the JWT payload and extracts the `sub` claim (Keycloak user UUID).
  String _subFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = json.decode(payload) as Map<String, dynamic>;
      return (claims['sub'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  // ───────────────────────── READ ─────────────────────────

  /// Loads the user's orders.
  ///
  /// [loadMore] = false (default): resets to page 1 and replaces the list.
  /// [loadMore] = true: fetches the next page and appends to the list.
  Future<void> fetchOrders({bool loadMore = false}) async {
    // Don't start a load-more if the first page is still in flight — the
    // page counter would be wrong and the append would race with the replace.
    if (loadMore) {
      if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    }

    if (userIri.value.isEmpty) {
      final ok = await fetchUserIri();
      if (!ok || userIri.value.isEmpty) {
        errorMessage.value = CustomerOrderStrings.errorIdentifyAccount;
        return;
      }
    }

    if (loadMore) {
      isLoadingMore.value = true;
      _page++;
    } else {
      _page = 1;
      isLoading.value = true;
      errorMessage.value = '';
    }

    try {
      final result = await _service.getOrders(
        userIri: userIri.value,
        page: _page,
      );

      totalOrders.value = result.totalOrders;

      if (loadMore) {
        orders.value = [...orders, ...result.orders];
      } else {
        orders.value = result.orders;
        // Cache first page so the next launch shows data immediately.
        DataCacheService.save(
          _cacheKey,
          result.orders.map((o) => o.toJson()).toList(),
        );
      }
      hasMore.value = result.hasNext;
      isFromCache.value = false;
    } catch (e, s) {
      if (loadMore) _page--;
      if (!loadMore && orders.isEmpty) {
        errorMessage.value = CustomerOrderStrings.errorLoadOrders;
      }
      _logError('fetchOrders', e, s);
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Loads every remaining page so [orders] holds the user's complete order
  /// history. [fetchOrders] normally only loads one page at a time — the
  /// impact tracker needs an exact lifetime total rather than just the most
  /// recent page, so it awaits this before aggregating.
  Future<void> loadAllOrders() async {
    if (orders.isEmpty && !isLoading.value) await fetchOrders();
    var guard = 0;
    while (hasMore.value && guard < 50) {
      await fetchOrders(loadMore: true);
      guard++;
    }
  }

  /// Loads the full details of one order by its [id]
  /// (used by the order details screen).
  Future<void> fetchOrderById(String id) async {
    isDetailLoading.value = true;
    errorMessage.value = '';

    try {
      var order = await _service.getOrderById(id);

      // The order API often omits images inside nested foodOffer objects.
      // Fetch missing offer images in parallel so the photo hero can appear.
      final needsImages = order.orderItems
          .where(
            (item) => item.foodOffer.images.isEmpty && item.foodOffer.id > 0,
          )
          .toList();
      if (needsImages.isNotEmpty) {
        final enriched = await Future.wait(
          order.orderItems.map((item) async {
            if (item.foodOffer.images.isNotEmpty || item.foodOffer.id == 0) {
              return item;
            }
            final full = await _service.getFoodOfferByIri(item.foodOffer.iri);
            return full != null ? item.withOffer(full) : item;
          }),
        );
        order = order.copyWith(orderItems: enriched);
      }

      selectedOrder.value = order;
    } catch (e, s) {
      errorMessage.value = CustomerOrderStrings.errorLoadDetail;
      _logError('fetchOrderById', e, s);
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ───────────────────────── WRITE ─────────────────────────

  /// Sends a new order to the backend.
  ///
  /// On success: shows a success message, refreshes the order list, and
  /// returns to the first screen. On failure: shows an error and rethrows
  /// so the calling screen can react (e.g. keep the checkout button enabled).
  /// [deliveryAddressIri] is null for pickup orders — see
  /// [OrderService.placeOrder] for why that must not be a hidden/stale value.
  Future<void> placeOrder({
    required String businessPartnerIri,
    String? deliveryAddressIri,
    required String notes,
    required String userIri,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'card',
  }) async {
    isPlacingOrder.value = true;

    // The caller already resolved the IRI to place the order — cache it so
    // the fetchOrders() call below can use it without another round-trip.
    if (this.userIri.value.isEmpty) {
      this.userIri.value = userIri;
    }

    try {
      // 1. Send the order. The 201 response carries the backend-assigned user
      //    IRI which may differ from what the JWT sub resolves to.
      final resolvedIri = await _service.placeOrder(
        businessPartnerIri: businessPartnerIri,
        deliveryAddressIri: deliveryAddressIri,
        notes: notes,
        items: items,
        paymentMethod: paymentMethod,
      );

      // Always overwrite with the authoritative IRI from the backend so that
      // fetchOrders() below queries with exactly the right identifier.
      if (resolvedIri != null && resolvedIri.isNotEmpty) {
        this.userIri.value = resolvedIri;
      }

      // 1.5. Reflect the new stock locally right away — otherwise the home/
      // search screens keep showing the pre-order quantity until the user
      // manually pulls to refresh.
      _reduceOfferQuantities(items);

      // 2. Tell the user it worked.
      AppSnackbar.success(
        CustomerOrderStrings.placedTitle,
        CustomerOrderStrings.placedBody,
        duration: const Duration(seconds: 3),
        position: SnackPosition.TOP,
      );

      // 3. Refresh the list so the new order shows up.
      await fetchOrders();

      // 4. Wait briefly so the user sees the success message,
      //    then go back to the first (home) screen.
      await Future.delayed(const Duration(seconds: 2));
      Get.until((route) => route.isFirst);
    } catch (e, s) {
      _logError('placeOrder', e, s);

      // Show the error to the user. order_service.placeOrder() throws a
      // plain Exception with the backend's detail message for known 400
      // cases (business closed, temporarily inactive, own-store order) — use
      // that verbatim instead of the generic fallback when available.
      final detail = (e is Exception && e is! DioException)
          ? e.toString().replaceFirst('Exception: ', '')
          : '';
      AppSnackbar.error(
        ErrorStrings.title,
        detail.isNotEmpty ? detail : CustomerOrderStrings.errorPlaceBody,
      );

      // ...and rethrow so the checkout screen knows it failed.
      rethrow;
    } finally {
      isPlacingOrder.value = false;
    }
  }

  /// Extracts offer id/quantity/weight from the raw request item maps built
  /// in [placeOrder]'s [items] and decrements local FoodOfferController
  /// state so browse screens reflect the new stock immediately, mirroring
  /// how [cancelOrder]/[deleteOrder] call [FoodOfferController.restoreQuantities].
  void _reduceOfferQuantities(List<Map<String, dynamic>> items) {
    final foodCtrl = Get.isRegistered<FoodOfferController>()
        ? Get.find<FoodOfferController>()
        : null;
    // Same reasoning as foodCtrl: without this, an item you just bought out
    // kept showing its stale pre-order stock on the Favorites screen (and
    // stayed tappable/reservable-looking) until the next full loadFavorites.
    final favCtrl = Get.isRegistered<FavoritesOfferController>()
        ? Get.find<FavoritesOfferController>()
        : null;
    // The customer home/search screen (CustomerFoodScreen) actually reads
    // from this tagged ProductController, not FoodOfferController — without
    // this, the stock shown there stayed stale until a manual pull-to-
    // refresh even though FoodOfferController's own (unused) copy updated.
    final productCtrl =
        Get.isRegistered<ProductController>(tag: Market.food.value)
        ? Get.find<ProductController>(tag: Market.food.value)
        : null;
    if (foodCtrl == null && favCtrl == null && productCtrl == null) return;
    for (final item in items) {
      final iri = item['product'] as String?;
      final id = iri == null ? null : int.tryParse(iri.split('/').last);
      if (id == null) continue;
      final quantity = item['quantity'] as int? ?? 0;
      final weightKg = double.tryParse(item['weightTotalKg']?.toString() ?? '');
      foodCtrl?.reduceQuantity(id, quantity: quantity, weightKg: weightKg);
      favCtrl?.reduceQuantity(id, quantity: quantity, weightKg: weightKg);
      productCtrl?.reduceQuantity(id, quantity: quantity, weightKg: weightKg);
    }
  }

  /// Restores stock on the tagged food [ProductController] too — see the
  /// matching comment in [_reduceOfferQuantities] for why this is needed
  /// alongside [FoodOfferController.restoreQuantities].
  void _restoreProductQuantities(List<OrderItemModel> items) {
    if (!Get.isRegistered<ProductController>(tag: Market.food.value)) return;
    Get.find<ProductController>(
      tag: Market.food.value,
    ).restoreQuantities(items);
  }

  // ───────────────────────── EDIT ORDER ─────────────────────────

  final isUpdating = false.obs;

  /// Updates a pending order's items, notes, and delivery address.
  Future<void> editOrder({
    required String orderId,
    required String notes,
    required String deliveryAddressIri,
    required Map<int, int> itemQuantities,
  }) async {
    isUpdating.value = true;
    try {
      await _service.updateOrder(
        orderId,
        notes: notes,
        deliveryAddressIri: deliveryAddressIri,
      );
      for (final entry in itemQuantities.entries) {
        await _service.updateOrderItem(entry.key, quantity: entry.value);
      }
      await fetchOrderById(orderId);
      Get.back(result: true);
      AppSnackbar.success(
        CustomerOrderStrings.updatedTitle,
        CustomerOrderStrings.updatedBody,
        position: SnackPosition.TOP,
      );
    } catch (e, s) {
      _logError('editOrder', e, s);
      AppSnackbar.error(ErrorStrings.title, CustomerOrderStrings.errorUpdateBody);
    } finally {
      isUpdating.value = false;
    }
  }

  // ───────────────────────── CANCEL ORDER ─────────────────────────

  /// Cancels a pending order by setting its status to "cancelled".
  /// If [reason] is provided it's saved as the order's cancellationReason in
  /// the same status-transition call.
  Future<void> cancelOrder(OrderModel order, {String? reason}) async {
    try {
      await _service.cancelOrder(order.id, reason: reason);
      // Update the order in the list optimistically.
      final idx = orders.indexWhere((o) => o.id == order.id);
      if (idx != -1) {
        orders[idx] = order.copyWith(
          status: 'cancelled',
          cancellationReason: reason?.isNotEmpty == true
              ? reason
              : order.cancellationReason,
        );
      }
      // Restore quantityAvailable on the affected offers immediately so the
      // home screen reflects the freed-up stock without a manual refresh.
      final restoreItems = await _itemsForRestore(order);
      Get.find<FoodOfferController>().restoreQuantities(restoreItems);
      if (Get.isRegistered<FavoritesOfferController>()) {
        Get.find<FavoritesOfferController>().restoreQuantities(restoreItems);
      }
      _restoreProductQuantities(restoreItems);
      AppSnackbar.success(
        CustomerOrderStrings.cancelledTitle,
        CustomerOrderStrings.cancelledBody(order.id),
        position: SnackPosition.TOP,
      );
    } catch (e, s) {
      _logError('cancelOrder', e, s);
      AppSnackbar.error(ErrorStrings.title, CustomerOrderStrings.errorCancelBody);
    }
  }

  // ───────────────────────── DELETE ORDER FROM LIST ─────────────────────────
  /// Deletes a whole order.
  ///
  /// Removes it from the list immediately so the swiped card disappears,
  /// then deletes it from the database. If that fails, the order is restored.
  Future<void> deleteOrder(OrderModel order) async {
    final index = orders.indexOf(order);
    if (index == -1) return;

    // 1. Optimistically remove from the visible list.
    orders.removeAt(index);

    // 2. Delete from the database.
    try {
      await _service.deleteOrder(order.id);
      // Restore stock for any pending order that gets hard-deleted.
      final restoreItems = await _itemsForRestore(order);
      Get.find<FoodOfferController>().restoreQuantities(restoreItems);
      if (Get.isRegistered<FavoritesOfferController>()) {
        Get.find<FavoritesOfferController>().restoreQuantities(restoreItems);
      }
      _restoreProductQuantities(restoreItems);
    } catch (e, s) {
      // 3. Failed — put it back where it was and tell the user.
      orders.insert(index, order);
      _logError('deleteOrder', e, s);
      AppSnackbar.error(ErrorStrings.title, CustomerOrderStrings.errorDeleteBody);
    }
  }
  // ───────────────────────── HELPERS ─────────────────────────

  void _logError(String where, Object error, StackTrace stackTrace) {
    AppLogger.error(
      'OrderController',
      where,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
