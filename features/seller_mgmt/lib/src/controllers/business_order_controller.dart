import 'dart:async';

import 'package:flutter/foundation.dart'; // for debugPrint / kDebugMode
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:notification/notification.dart';
import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:core/core.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Handles the BUSINESS PARTNER's orders: the queue of orders customers
/// placed with this business, the details of one order, and moving an order
/// through its lifecycle (accept / mark delivered / reject).
///
/// Mirrors the customer OrderController, but:
///  - fetches orders placed WITH this business (not the user's own)
///  - has updateStatus instead of placeOrder / deleteOrder
class BusinessOrderController extends GetxController {
  BusinessOrderController(this._service);

  final OrderService _service;
  static const _tag = 'BusinessOrderController';
  static const _mercure = MercureService();

  // ───────────────────────── STATE ─────────────────────────

  /// All orders placed with this business (for the partner order list).
  final orders = <OrderModel>[].obs;
  final isLoading = false.obs; // True while loading the list.

  /// True when there's a New or Active order waiting on the partner — drives
  /// the plain attention dot on the Orders nav item (no count, by design;
  /// see the badge builders in business_dashboard_screen.dart). Reads the
  /// raw list rather than [filteredForBucket] so it's unaffected by whatever
  /// search/date filter happens to be set on the Orders screen right now.
  bool get hasNewOrActiveOrders => orders.any(
    (o) => o.bucket == OrderBucket.incoming || o.bucket == OrderBucket.active,
  );

  /// The order currently open on the details screen.
  final selectedOrder = Rxn<OrderModel>();
  final isDetailLoading = false.obs; // True while loading details.

  /// True while a status change is in flight.
  final isUpdating = false.obs;

  /// Error text for the UI (empty = no error).
  final errorMessage = ''.obs;

  /// Timestamp of the most recent completed fetch attempt (success or failure).
  /// Used to throttle auto-refreshes triggered by tab switches so a server
  /// timeout doesn't restart every time the user changes tabs.
  DateTime? _lastFetchAttempt;

  /// Minimum time between automatic fetches. Explicit refreshes (pull-to-refresh,
  /// status updates) bypass this via [force: true].
  static const _fetchCooldown = Duration(seconds: 30);

  /// True while showing cached orders from the previous session.
  final isFromCache = false.obs;

  static const _cacheKey = 'business_orders';

  // ─────────────────── FILTER / SEARCH STATE ───────────────────
  final searchQuery = ''.obs;
  final sortOrder = OrderSortOrder.newest.obs;
  final dateFilter = OrderDateFilter.all.obs;
  final doneStatusFilter = DoneOrderFilter.all.obs;

  // ─────────────────── Real-time updates (Mercure) ───────────────────
  StreamSubscription? _mercureSub;
  Worker? _mercureTokenWorker;

  @override
  void onInit() {
    super.onInit();
    _loadCachedOrders();
    final bpCtrl = Get.find<BusinessPartnerController>();

    if (bpCtrl.partner.value != null) {
      // Partner already in memory — fetch immediately, no watcher needed.
      fetchOrders();
    } else {
      // Partner not loaded yet. Register a one-shot worker that fires exactly
      // once when the partner transitions from null to a real object.
      // Using a self-disposing worker prevents re-triggering on subsequent
      // partner.value changes caused by optimistic updates in setIsOpen() /
      // setAcceptsCashPayment(), which would launch unnecessary concurrent
      // fetches and risk concurrent token-refresh race conditions.
      Worker? initWorker;
      initWorker = ever(bpCtrl.partner, (partner) {
        if (partner != null) {
          initWorker?.dispose();
          initWorker = null;
          fetchOrders();
        }
      });
    }

    _connectMercure();
  }

  @override
  void onClose() {
    _mercureSub?.cancel();
    _mercureTokenWorker?.dispose();
    super.onClose();
  }

  // ─────────────────── Real-time updates (Mercure) ───────────────────

  /// Opens the SSE subscription to this business's private orders topic
  /// (`business-partners/{id}/orders`, from [MercureController]) and starts
  /// listening for the credential being refreshed, so this reconnects with a
  /// fresh token automatically rather than running its own JWT-exp timer.
  ///
  /// [MercureController] refreshes proactively (by JWT exp) rather than
  /// reacting to an auth-specific disconnect: the underlying SSE package
  /// never surfaces the HTTP status code of the connection to callers — on a
  /// 401 it just looks exactly like a normal idle reconnect (silent retry,
  /// no error we can catch) — so there's no reliable signal to react to
  /// after the fact.
  Future<void> _connectMercure() async {
    final mercureCtrl = Get.find<MercureController>();
    await mercureCtrl.ensureLoaded();
    _subscribeToBusinessOrders(mercureCtrl);

    _mercureTokenWorker?.dispose();
    _mercureTokenWorker = ever(mercureCtrl.tokenRx, (_) {
      _subscribeToBusinessOrders(mercureCtrl);
    });
  }

  void _subscribeToBusinessOrders(MercureController mercureCtrl) {
    final token = mercureCtrl.token;
    final topic = mercureCtrl.businessOrdersTopic;
    if (token == null || topic == null) {
      _logError(
        '_subscribeToBusinessOrders',
        'No Mercure token/topic available yet',
        StackTrace.current,
      );
      return;
    }
    _mercureSub?.cancel();
    _mercureSub = _mercure.subscribeToOrders(
      topic: topic,
      token: token,
      onOrder: (order) {
        AppLogger.info(
          _tag,
          'Mercure: order ${order.id} → ${order.status} — refreshing',
        );
        fetchOrders(force: true);
        // A new order likely just decremented some offer's remaining
        // quantity/weight — refresh the Menu tab's list too (same "list
        // vs. detail can independently go stale" class of bug fixed for
        // OrderController.refreshAfterOrderChange, see
        // [[project_mercure_realtime]]), but only if the partner has
        // actually opened Menu this session — Get.isRegistered avoids
        // creating BusinessOfferController just to immediately fetch on a
        // tab nobody is looking at.
        if (Get.isRegistered<BusinessOfferController>()) {
          final partnerId = Get.find<BusinessPartnerController>().partnerId;
          if (partnerId != 0) {
            Get.find<BusinessOfferController>().fetchMyOffers(partnerId);
          }
        }
      },
    );
  }

  // ───────────────────────── READ ─────────────────────────

  /// Shows the last-known order queue immediately (if any and not stale)
  /// while [fetchOrders] fetches the fresh list in the background.
  void _loadCachedOrders() {
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
  }

  /// Loads the orders placed with this business.
  ///
  /// Returns early when a fetch is already in progress or the business partner
  /// IRI is not available yet — the one-shot worker in [onInit] will call this
  /// once the partner loads.
  Future<void> fetchOrders({bool force = false}) async {
    // Guard: drop concurrent calls.
    if (isLoading.value) return;

    // Throttle automatic tab-switch refreshes. After a timeout the server may
    // still be unreachable — no point hammering it every time the user switches
    // tabs. Explicit refreshes (pull-to-refresh, post status-update) pass force.
    if (!force && _lastFetchAttempt != null) {
      if (DateTime.now().difference(_lastFetchAttempt!) < _fetchCooldown)
        return;
    }

    final bpCtrl = Get.find<BusinessPartnerController>();

    // If the partner hasn't loaded yet (e.g. controller was freshly created or
    // the user hit refresh before the initial fetch completed), fetch it now.
    if (bpCtrl.partner.value == null) {
      await bpCtrl.fetchMyPartner();
    }

    final partnerIri = bpCtrl.partner.value?.iri;

    // Without a partner IRI the backend would reject the request with 401
    // because an unfiltered GET /orders is not allowed for business accounts.
    if (partnerIri == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      orders.value = await _service.getBusinessOrders(
        businessPartnerIri: partnerIri,
      );
      isFromCache.value = false;
      await DataCacheService.save(
        _cacheKey,
        orders.map((o) => o.toJson()).toList(),
      );
    } catch (e, s) {
      errorMessage.value = 'Could not load your orders';
      _logError('fetchOrders', e, s);
    } finally {
      _lastFetchAttempt = DateTime.now();
      isLoading.value = false;
    }
  }

  /// Loads the full details of one order by its [id]
  /// (used by the order details screen).
  Future<void> fetchOrderById(String id) async {
    isDetailLoading.value = true;
    errorMessage.value = '';

    try {
      selectedOrder.value = await _service.getOrderById(id);
    } catch (e, s) {
      errorMessage.value = 'Could not load order details';
      _logError('fetchOrderById', e, s);
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ───────────────────────── WRITE ─────────────────────────

  /// Changes an order's status (e.g. confirmed, delivered, cancelled).
  ///
  /// Optimistically swaps the order in the visible list, then sends the
  /// change to the backend. On success the server's version replaces it;
  /// on failure the previous order is restored and the user is told.
  Future<void> updateStatus(OrderModel order, String newStatus) async {
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index == -1) return;

    isUpdating.value = true;
    errorMessage.value = '';

    // Optimistic update: move the card to the target bucket immediately so
    // the UI feels instant. Rolled back if the API call fails.
    final previous = orders[index];
    orders[index] = previous.copyWith(status: newStatus);

    try {
      await _service.updateOrderStatus(order.id, newStatus);

      // Restoring stock is a one-time credit — only do it on the actual
      // pending→cancelled transition, not e.g. a retry that lands here
      // again with the order already cancelled.
      if (newStatus == 'cancelled' &&
          previous.status.toLowerCase() != 'cancelled' &&
          Get.isRegistered<BusinessOfferController>()) {
        Get.find<BusinessOfferController>().restoreQuantities(
          await _itemsForRestore(order),
        );
      }

      await fetchOrders(force: true); // reconcile with server-canonical data

      if (selectedOrder.value?.id == order.id) {
        await fetchOrderById(order.id); // keep detail view in sync
      }

      AppSnackbar.success('common_successTitle'.tr, 'bizOrder_statusUpdated'.tr);
    } catch (e, s) {
      orders[index] = previous; // rollback on failure
      _logError('updateStatus', e, s);
      AppSnackbar.error(ErrorStrings.title, 'bizOrder_updateError'.tr);
    } finally {
      isUpdating.value = false;
    }
  }

  /// Returns items safe to pass to a stock-restore call.
  ///
  /// `productId` is a plain int column on `OrderItem` (no ORM relation since
  /// the Phase C catalog-service split), so it's reliably present on both the
  /// list endpoint (`GET /orders?businessPartner=...`) and the detail one
  /// (`GET /orders/{id}`) — unlike the old embedded `foodOffer`/`product`
  /// object, which the backend no longer serializes at all. Refetching detail
  /// is now just a defensive fallback for the rare case [order]'s items don't
  /// have it yet.
  Future<List<OrderItemModel>> _itemsForRestore(OrderModel order) async {
    if (order.orderItems.every((i) => i.productId > 0)) {
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

  /// Convenience wrappers so screens read clearly.
  Future<void> accept(OrderModel order) => updateStatus(order, 'confirmed');
  Future<void> reject(OrderModel order) => updateStatus(order, 'cancelled');
  Future<void> markDelivered(OrderModel order) =>
      updateStatus(order, 'delivered');

  Future<void> cancel(OrderModel order) => updateStatus(order, 'cancelled');

  // Reverse of _nextStatus. Adjust to your real lifecycle.
  String _previousStatus(String s) =>
      OrderStatusEnums.fromValue(s).previous?.value ?? s;

  Future<void> moveBack(OrderModel order) {
    final prev = _previousStatus(order.status);
    if (prev == order.status) return Future.value(); // nothing to do
    return updateStatus(order, prev);
  }
  // ─────────────────── FILTER / SEARCH LOGIC ───────────────────

  /// Returns orders for the given [bucket] after applying search, date, and sort.
  List<OrderModel> filteredForBucket(OrderBucket bucket) {
    var list = orders.where((o) => o.bucket == bucket).toList();

    if (dateFilter.value != OrderDateFilter.all) {
      final now = DateTime.now();
      list = list.where((o) {
        final d = o.createdAtDate;
        if (d == null) return false;
        if (dateFilter.value == OrderDateFilter.today) {
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }
        return d.isAfter(now.subtract(const Duration(days: 7)));
      }).toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) {
        if (o.id.toLowerCase().contains(q)) return true;
        final name = '${o.user?.firstName ?? ''} ${o.user?.lastName ?? ''}'
            .toLowerCase();
        if (name.contains(q)) return true;
        return o.orderItems.any(
          (i) => i.titleSnapshot.toLowerCase().contains(q),
        );
      }).toList();
    }

    if (bucket == OrderBucket.done) {
      // Status sub-filter — apply before sort so limits keep the freshest items.
      final statusF = doneStatusFilter.value;
      if (statusF != DoneOrderFilter.all) {
        list = list.where((o) => statusF.matches(o.status)).toList();
      }

      // Always newest-first: pick the most recent timestamp available for each
      // order. completedAt/cancelledAt are preferred; fall back to updatedAt
      // then createdAt so the sort never silently breaks on missing fields.
      list.sort((a, b) {
        final da = _bestDoneTime(a);
        final db = _bestDoneTime(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    } else {
      list.sort((a, b) {
        final da = DateTime.tryParse(a.createdAt)?.toUtc();
        final db = DateTime.tryParse(b.createdAt)?.toUtc();
        if (da == null || db == null) return 0;
        return sortOrder.value == OrderSortOrder.newest
            ? db.compareTo(da)
            : da.compareTo(db);
      });
    }

    return list;
  }

  /// Counts Done-bucket orders for each [DoneOrderFilter] after applying date
  /// and search filters — but BEFORE applying the status sub-filter — so the
  /// chip badges always reflect how many items each filter would reveal.
  Map<DoneOrderFilter, int> get doneBucketCounts {
    var list = orders.where((o) => o.bucket == OrderBucket.done).toList();

    if (dateFilter.value != OrderDateFilter.all) {
      final now = DateTime.now();
      list = list.where((o) {
        final d = o.createdAtDate;
        if (d == null) return false;
        if (dateFilter.value == OrderDateFilter.today) {
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }
        return d.isAfter(now.subtract(const Duration(days: 7)));
      }).toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) {
        if (o.id.toLowerCase().contains(q)) return true;
        final name = '${o.user?.firstName ?? ''} ${o.user?.lastName ?? ''}'
            .toLowerCase();
        if (name.contains(q)) return true;
        return o.orderItems.any(
          (i) => i.titleSnapshot.toLowerCase().contains(q),
        );
      }).toList();
    }

    return {
      for (final f in DoneOrderFilter.values)
        f: f == DoneOrderFilter.all
            ? list.length
            : list.where((o) => f.matches(o.status)).length,
    };
  }

  void clearFilters() {
    searchQuery.value = '';
    sortOrder.value = OrderSortOrder.newest;
    dateFilter.value = OrderDateFilter.all;
    doneStatusFilter.value = DoneOrderFilter.all;
  }

  // ───────────────────────── HELPERS ─────────────────────────

  /// Returns the best available "action time" for a done order.
  ///
  /// Priority: completedAt → cancelledAt → updatedAt → createdAt.
  /// Returns the first one that parses successfully, or null if none do.
  DateTime? _bestDoneTime(OrderModel o) {
    final candidates = [o.completedAt, o.cancelledAt, o.updatedAt, o.createdAt];
    for (final s in candidates) {
      if (s == null || s.isEmpty) continue;
      final dt = DateTime.tryParse(s);
      if (dt != null) return dt.toUtc();
    }
    return null;
  }

  /// Debug-only logging. Swap for your logger/Crashlytics in one place.
  void _logError(String where, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[BusinessOrderController.$where] $error\n$stackTrace');
    }
  }
}
