import 'package:get/get.dart';

import 'package:food_app/constants/cosmetic/cosmetic_strings.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/models/product_models/product_order_model.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/services/product_order_service.dart';
import 'package:food_app/profile_and_orders/orders/controllers/order_controller.dart';
import 'package:food_app/strings/error_strings.dart';
import 'package:food_app/utils/app_logger.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';

/// Owns checkout and order-history for the generic Product catalog — the
/// market-agnostic counterpart to the parts of `OrderController` that are
/// Food-specific. Deliberately independent of `OrderController`'s own
/// `orders`/pagination state (so Food's order list is never touched), but
/// reuses its `fetchUserIri()` for resolving the current user's IRI — that
/// logic (JWT decode → API fallback) has nothing to do with Food and isn't
/// worth a second copy.
class ProductOrderController extends GetxController {
  ProductOrderController(this._service);

  final ProductOrderService _service;
  static const _tag = 'ProductOrderController';

  final orders = <ProductOrderModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;
  final isPlacingOrder = false.obs;
  final placeOrderError = RxnString();

  // ── Order detail (mirrors OrderController.selectedOrder/isDetailLoading) ──
  final selectedOrder = Rxn<ProductOrderModel>();
  final isDetailLoading = false.obs;
  final isUpdating = false.obs;

  // No cache layer for Product orders yet — always "fresh".
  final isFromCache = false.obs;

  // ── Order-list filter state (mirrors OrderController) ────────────────────
  final searchQuery = ''.obs;
  final sortOrder = CustomerOrderSort.newest.obs;
  final statusFilter = CustomerOrderStatusFilter.all.obs;
  final dateFilter = OrderDateFilter.all.obs;

  /// Returns [orders] filtered and sorted by the current filter state — same
  /// shape as `OrderController.filteredOrders`. Call inside `Obx` so the list
  /// rebuilds whenever any filter changes.
  List<ProductOrderModel> get filteredOrders {
    // `/orders` is a shared, market-agnostic endpoint — the raw response
    // spans every market, so this (shared across every non-Food market, see
    // the binding comment on this controller) must filter Food's orders back
    // out itself or a customer who also has Food orders would see both
    // mixed together here. Keyed off the order's own category snapshot
    // rather than `businessPartner.markets` (not reliably present on this
    // list response) — see `isCosmeticCategory`'s doc comment.
    var result = orders
        .where(
          (o) =>
              o.orderItems.isNotEmpty &&
              isCosmeticCategory(o.orderItems.first.categorySnapshot),
        )
        .toList();

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((o) {
        return o.id.toLowerCase().contains(q) ||
            o.businessPartner.businessName.toLowerCase().contains(q);
      }).toList();
    }

    final status = statusFilter.value.apiValue;
    if (status != null) {
      result = result.where((o) => o.status.toLowerCase() == status).toList();
    }

    if (dateFilter.value != OrderDateFilter.all) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 6));
      result = result.where((o) {
        final d = DateTime.tryParse(o.createdAt);
        if (d == null) return false;
        if (dateFilter.value == OrderDateFilter.today)
          return !d.isBefore(today);
        return !d.isBefore(weekAgo);
      }).toList();
    }

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

  int _page = 1;

  // ── Business-side order queue ─────────────────────────────────────────────
  final businessOrders = <ProductOrderModel>[].obs;
  final isLoadingBusinessOrders = false.obs;
  final businessOrdersError = ''.obs;

  Future<void> fetchBusinessOrders(String businessPartnerIri) async {
    isLoadingBusinessOrders.value = true;
    businessOrdersError.value = '';
    try {
      businessOrders.value = await _service.getBusinessOrders(
        businessPartnerIri: businessPartnerIri,
      );
    } catch (e) {
      AppLogger.error(_tag, 'fetchBusinessOrders failed', error: e);
      businessOrdersError.value = 'productOrder_errorLoad'.tr;
    } finally {
      isLoadingBusinessOrders.value = false;
    }
  }

  /// Advances (or cancels) a business order, then refreshes the queue so the
  /// list reflects the new status immediately.
  Future<bool> advanceBusinessOrder(
    String orderId,
    String newStatus,
    String businessPartnerIri,
  ) async {
    final ok = await updateOrderStatus(orderId, newStatus);
    if (ok) await fetchBusinessOrders(businessPartnerIri);
    return ok;
  }

  Future<String?> _resolveUserIri() async {
    final orderController = Get.find<OrderController>();
    if (orderController.userIri.value.isNotEmpty) {
      return orderController.userIri.value;
    }
    final ok = await orderController.fetchUserIri();
    return ok ? orderController.userIri.value : null;
  }

  Future<void> fetchOrders({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    }

    final userIri = await _resolveUserIri();
    if (userIri == null || userIri.isEmpty) {
      errorMessage.value = 'productOrder_errorIdentifyAccount'.tr;
      return;
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
      final result = await _service.getOrders(userIri: userIri, page: _page);
      orders.value = loadMore ? [...orders, ...result.orders] : result.orders;
      hasMore.value = result.hasNext;
    } catch (e) {
      AppLogger.error(_tag, 'fetchOrders failed', error: e);
      if (!loadMore) errorMessage.value = 'productOrder_errorLoad'.tr;
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Places a new product-order. Returns true on success; on failure
  /// [placeOrderError] holds a human-readable message.
  Future<bool> placeOrder({
    required String businessPartnerIri,
    String? deliveryAddressIri,
    required String notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'card',
  }) async {
    isPlacingOrder.value = true;
    placeOrderError.value = null;
    try {
      await _service.placeOrder(
        businessPartnerIri: businessPartnerIri,
        deliveryAddressIri: deliveryAddressIri,
        notes: notes,
        items: items,
        paymentMethod: paymentMethod,
      );
      return true;
    } catch (e) {
      AppLogger.error(_tag, 'placeOrder failed', error: e);
      placeOrderError.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isPlacingOrder.value = false;
    }
  }

  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _service.cancelOrder(orderId, reason: reason);
      final idx = orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        await fetchOrders();
      }
      return true;
    } catch (e) {
      AppLogger.error(_tag, 'cancelOrder failed', error: e);
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _service.updateOrderStatus(orderId, newStatus);
      return true;
    } catch (e) {
      AppLogger.error(_tag, 'updateOrderStatus failed', error: e);
      return false;
    }
  }

  // ───────────────────────── ORDER DETAIL ─────────────────────────

  /// Loads the full details of one product-order by its [id] — used by the
  /// Cosmetic order-detail screen so it (like Food's) always shows a
  /// freshly-fetched order with a real, non-null `product` on each item.
  /// Mirrors `OrderController.fetchOrderById`.
  Future<void> fetchOrderById(String id) async {
    isDetailLoading.value = true;
    try {
      selectedOrder.value = await _service.getOrderById(id);
    } catch (e) {
      AppLogger.error(_tag, 'fetchOrderById failed', error: e);
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ───────────────────────── EDIT ORDER ─────────────────────────

  /// Updates a pending product-order's items, notes, and delivery address.
  /// Mirrors `OrderController.editOrder`.
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
      await fetchOrders();
      Get.back(result: true);
      AppSnackbar.success(
        CustomerOrderStrings.updatedTitle,
        CustomerOrderStrings.updatedBody,
        position: SnackPosition.TOP,
      );
    } catch (e) {
      AppLogger.error(_tag, 'editOrder failed', error: e);
      AppSnackbar.error(ErrorStrings.title, CustomerOrderStrings.errorUpdateBody);
    } finally {
      isUpdating.value = false;
    }
  }
}
