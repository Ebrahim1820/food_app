// Customer order-history screen for the Food market. Thin wiring layer over
// the generic OrderListScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/order_list_screen.dart)
// — the same generic screen Cosmetic's order list wires up. This file owns
// everything Food-specific: OrderController, the review-preload call, the
// OrderSummaryCard row widget, and swipe-to-delete + its confirmation dialog.
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:review/review.dart';
import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import '../../discovery/views/order_detail_screen.dart'
    show isPendingOrderStatus, isTerminalOrderStatus;
import '../../discovery/views/order_list_screen.dart'
    as shared;
import 'package:get/get.dart';

/// Customer order history screen: search, sort/filter chips, and the order list.
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key, required this.searchController});

  /// Owned by AppShellScreen (its AppBar renders the actual search field) —
  /// passed down only so the "Clear filters" button here can call .clear()
  /// on it too.
  final TextEditingController searchController;

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderController controller = Get.find<OrderController>();

  @override
  void initState() {
    super.initState();
    controller.fetchOrders();
    // One bulk "which of my orders have I already rated?" lookup so each
    // completed order's card knows its footer state on the very first
    // frame — see ReviewController.preloadReviewedOrders for why this
    // replaces N per-card checks instead of just being a nice-to-have.
    Get.find<ReviewController>().preloadReviewedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return shared.OrderListScreen<OrderModel>(
      config: shared.OrderListConfig<OrderModel>(
        rawOrders: controller.orders,
        filterAndSort: (_) => controller.filteredOrders,
        keyOf: (order) => order.id,

        isLoading: controller.isLoading,
        isLoadingMore: controller.isLoadingMore,
        errorMessage: controller.errorMessage,
        isFromCache: controller.isFromCache,

        searchQuery: controller.searchQuery,
        sortOrder: controller.sortOrder,
        statusFilter: controller.statusFilter,
        dateFilter: controller.dateFilter,

        onRefresh: () => controller.fetchOrders(),
        onLoadMore: () => controller.fetchOrders(loadMore: true),

        // Stable per-order key — OrderSummaryCard does async work in
        // initState and setState on completion; the generic list already
        // wraps this in a KeyedSubtree/Dismissible keyed by keyOf so an
        // in-flight callback for one order can't land on a State object
        // Flutter has since reconfigured for a different order.
        itemBuilder: (order) => OrderSummaryCard(order: order),
        deleteConfig: shared.OrderListDeleteConfig<OrderModel>(
          // Only pending orders can be swiped to delete.
          canDelete: (order) => isPendingOrderStatus(order.status),
          confirmDelete: _confirmDelete,
          onDelete: controller.deleteOrder,
        ),

        // Active/Done sections — no separate "incoming" bucket here (unlike
        // the business side's OrderBucket): a customer just needs "is this
        // still happening" vs "it's over".
        isDone: (order) => isTerminalOrderStatus(order.status),
        activeSectionLabel: CustomerOrderStrings.sectionActive,
        doneSectionLabel: CustomerOrderStrings.sectionDone,

        sortNewestLabel: CustomerOrderStrings.sortNewest,
        sortOldestLabel: CustomerOrderStrings.sortOldest,
        sortPriceLabel: (sort) => switch (sort) {
          CustomerOrderSort.priceLowHigh =>
            CustomerOrderStrings.sortPriceLowHigh,
          CustomerOrderSort.priceHighLow =>
            CustomerOrderStrings.sortPriceHighLow,
          _ => CustomerOrderStrings.sortPrice,
        },
        filterTodayLabel: CustomerOrderStrings.filterToday,
        filterThisWeekLabel: CustomerOrderStrings.filterThisWeek,

        emptyTitle: CustomerOrderStrings.emptyTitle,
        emptySubtitle: CustomerOrderStrings.emptySubtitle,
        filteredEmptyTitle: CustomerOrderStrings.filteredEmptyTitle,
        filteredEmptySubtitle: CustomerOrderStrings.filteredEmptySubtitle,
        clearFiltersButtonLabel: CustomerOrderStrings.clearFiltersButton,
        tryAgainLabel: CustomerOrderStrings.tryAgain,
        onClearFilters: () {
          widget.searchController.clear();
          controller.searchQuery.value = '';
          controller.statusFilter.value = CustomerOrderStatusFilter.all;
          controller.dateFilter.value = OrderDateFilter.all;
          controller.sortOrder.value = CustomerOrderSort.newest;
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(CustomerOrderStrings.deleteDialogTitle),
        content: Text(CustomerOrderStrings.deleteDialogBody(order.id)),
        actions: [
          CustomDynamicButton(
            variant: CustomButtonVariant.text,
            label: CustomerOrderStrings.deleteDialogCancel,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CustomDynamicButton(
            variant: CustomButtonVariant.text,
            accentColor: AppColors.error,
            label: CustomerOrderStrings.deleteDialogConfirm,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
