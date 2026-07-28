import 'package:get/get.dart';

import 'package:food_app/controllers/prodcuct_controllers/product_order_controller.dart';
import 'package:models/models.dart';
import 'package:food_app/models/product_models/product_order_model.dart';
import 'package:food_app/profile_and_orders/orders/controllers/order_controller.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';

/// Which market a [DashboardOrderEntry] came from.
enum OrderMarket { food, cosmetic }

/// One row in the Dashboard's combined order list — wraps either an
/// [OrderModel] (Food) or a [ProductOrderModel] (Cosmetic) behind one shared
/// shape, so both can sit in the same generic `OrderListScreen<T>`.
class DashboardOrderEntry {
  final OrderMarket market;
  final OrderModel? _foodOrder;
  final ProductOrderModel? _cosmeticOrder;

  const DashboardOrderEntry.food(OrderModel order)
    : market = OrderMarket.food,
      _foodOrder = order,
      _cosmeticOrder = null;

  const DashboardOrderEntry.cosmetic(ProductOrderModel order)
    : market = OrderMarket.cosmetic,
      _foodOrder = null,
      _cosmeticOrder = order;

  bool get isFood => market == OrderMarket.food;
  OrderModel get foodOrder => _foodOrder!;
  ProductOrderModel get cosmeticOrder => _cosmeticOrder!;

  String get id => isFood ? foodOrder.id : cosmeticOrder.id;
  String get status => isFood ? foodOrder.status : cosmeticOrder.status;
  String get createdAt =>
      isFood ? foodOrder.createdAt : cosmeticOrder.createdAt;
  String get businessName => isFood
      ? foodOrder.businessPartner.businessName
      : cosmeticOrder.businessPartner.businessName;
  double get totalPriceValue =>
      double.tryParse(
        isFood ? foodOrder.totalPrice : cosmeticOrder.totalPrice,
      ) ??
      0;
}

/// Combines Food's [OrderController] and Cosmetic's [ProductOrderController]
/// into one merged, independently-filterable order list for the Dashboard's
/// "all markets" Orders tab.
///
/// Deliberately NOT a true unified pagination cursor — each controller pages
/// independently exactly as it already does for its own market's Orders
/// tab; [loadMoreAll] just nudges both and the merge recomputes. Slightly
/// wasteful (pages in both even if only one has more), but order histories
/// aren't huge, and a real cross-backend cursor isn't worth the complexity
/// here. Food's and Cosmetic's own Orders screens are completely untouched —
/// this only reads their existing reactive state and calls the same
/// fetch/loadMore/delete methods those screens already use.
///
/// Filter state (search/sort/status/date) is this merger's own, deliberately
/// not shared with either market's screen — switching to the Dashboard tab
/// shouldn't leak filters into Food's or Cosmetic's own order lists.
class DashboardOrdersMerger {
  DashboardOrdersMerger(this._foodCtrl, this._cosmeticCtrl) {
    _recompute();
    _recomputeLoading();
    _recomputeLoadingMore();
    _recomputeError();
    _workers = [
      ever(_foodCtrl.orders, (_) => _recompute()),
      ever(_cosmeticCtrl.orders, (_) => _recompute()),
      ever(_foodCtrl.isLoading, (_) => _recomputeLoading()),
      ever(_cosmeticCtrl.isLoading, (_) => _recomputeLoading()),
      ever(_foodCtrl.isLoadingMore, (_) => _recomputeLoadingMore()),
      ever(_cosmeticCtrl.isLoadingMore, (_) => _recomputeLoadingMore()),
      ever(_foodCtrl.errorMessage, (_) => _recomputeError()),
      ever(_cosmeticCtrl.errorMessage, (_) => _recomputeError()),
    ];
  }

  final OrderController _foodCtrl;
  final ProductOrderController _cosmeticCtrl;
  late final List<Worker> _workers;

  final rawOrders = <DashboardOrderEntry>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  // No shared cache layer for the combined view yet.
  final isFromCache = false.obs;

  final searchQuery = ''.obs;
  final sortOrder = CustomerOrderSort.newest.obs;
  final statusFilter = CustomerOrderStatusFilter.all.obs;
  final dateFilter = OrderDateFilter.all.obs;

  void _recompute() {
    rawOrders.assignAll([
      ..._foodCtrl.orders.map(DashboardOrderEntry.food),
      ..._cosmeticCtrl.orders.map(DashboardOrderEntry.cosmetic),
    ]);
  }

  void _recomputeLoading() => isLoading.value =
      _foodCtrl.isLoading.value || _cosmeticCtrl.isLoading.value;

  void _recomputeLoadingMore() => isLoadingMore.value =
      _foodCtrl.isLoadingMore.value || _cosmeticCtrl.isLoadingMore.value;

  /// Only surfaces a blocking error when BOTH sources failed and neither has
  /// any orders loaded — one market having a transient hiccup shouldn't hide
  /// the other market's perfectly good list.
  void _recomputeError() {
    final bothFailed =
        _foodCtrl.errorMessage.value.isNotEmpty &&
        _cosmeticCtrl.errorMessage.value.isNotEmpty;
    errorMessage.value = (bothFailed && rawOrders.isEmpty)
        ? _foodCtrl.errorMessage.value
        : '';
  }

  Future<void> refreshAll() async {
    await Future.wait([_foodCtrl.fetchOrders(), _cosmeticCtrl.fetchOrders()]);
  }

  Future<void> loadMoreAll() async {
    await Future.wait([
      _foodCtrl.fetchOrders(loadMore: true),
      _cosmeticCtrl.fetchOrders(loadMore: true),
    ]);
  }

  // Only Food supports swipe-to-delete today (pending orders only) — same
  // rule OrderSummaryCard/order_list_screen.dart already enforce.
  bool canDelete(DashboardOrderEntry e) =>
      e.isFood && e.foodOrder.status.toLowerCase() == 'pending';

  void deleteFoodOrder(DashboardOrderEntry e) =>
      _foodCtrl.deleteOrder(e.foodOrder);

  /// Same filter/sort shape as `OrderController.filteredOrders` /
  /// `ProductOrderController.filteredOrders`, generalized over the merged
  /// entry type.
  List<DashboardOrderEntry> filteredAndSorted(List<DashboardOrderEntry> raw) {
    var result = raw.toList();

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (o) =>
                o.id.toLowerCase().contains(q) ||
                o.businessName.toLowerCase().contains(q),
          )
          .toList();
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
        result.sort((a, b) => b.totalPriceValue.compareTo(a.totalPriceValue));
      case CustomerOrderSort.priceLowHigh:
        result.sort((a, b) => a.totalPriceValue.compareTo(b.totalPriceValue));
    }

    return result;
  }

  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
  }
}
