// Combined customer order-history screen for the Dashboard (no specific
// market selected) — shows Food and Cosmetic orders together in one list,
// each row tagged with a small market badge. Thin wiring layer over the
// generic OrderListScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/order_list_screen.dart),
// same as Food's and Cosmetic's own Orders screens — this is purely a third
// wiring layer on top of [DashboardOrdersMerger]; neither of those two
// screens is touched by this file.
import 'package:flutter/material.dart';
import 'package:food_app/screens/cosmetic_teil/orders/views/cosmetic_order_list_screen.dart'
    show CosmeticOrderCard;
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/theme/market_colors.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/profile_and_orders/orders/views/order_summary_card.dart';
import 'package:food_app/screens/dashboard/view/dashboard_orders_merger.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/order_list_screen.dart'
    as shared;
import 'package:food_app/strings/app_strings.dart';
import 'package:food_app/theme/app_colors.dart';

class DashboardOrderListScreen extends StatefulWidget {
  const DashboardOrderListScreen({super.key, required this.merger});

  final DashboardOrdersMerger merger;

  @override
  State<DashboardOrderListScreen> createState() =>
      _DashboardOrderListScreenState();
}

class _DashboardOrderListScreenState extends State<DashboardOrderListScreen> {
  @override
  void initState() {
    super.initState();
    // Unlike Food's/Cosmetic's own Orders screens, this combined view can
    // be the first Orders screen the user ever opens — so it can't assume
    // either controller has already fetched anything.
    WidgetsBinding.instance.addPostFrameCallback((_) => merger.refreshAll());
  }

  DashboardOrdersMerger get merger => widget.merger;

  @override
  Widget build(BuildContext context) {
    return shared.OrderListScreen<DashboardOrderEntry>(
      config: shared.OrderListConfig<DashboardOrderEntry>(
        rawOrders: merger.rawOrders,
        filterAndSort: merger.filteredAndSorted,
        // Market-prefixed — Food and Cosmetic orders come from separate
        // controllers, so ids alone aren't guaranteed unique across markets.
        keyOf: (e) => '${e.market.name}-${e.id}',

        isLoading: merger.isLoading,
        isLoadingMore: merger.isLoadingMore,
        errorMessage: merger.errorMessage,
        isFromCache: merger.isFromCache,

        searchQuery: merger.searchQuery,
        sortOrder: merger.sortOrder,
        statusFilter: merger.statusFilter,
        dateFilter: merger.dateFilter,

        onRefresh: merger.refreshAll,
        onLoadMore: merger.loadMoreAll,

        itemBuilder: (entry) => _DashboardOrderTile(entry: entry),
        deleteConfig: shared.OrderListDeleteConfig<DashboardOrderEntry>(
          canDelete: merger.canDelete,
          confirmDelete: _confirmDelete,
          onDelete: merger.deleteFoodOrder,
        ),

        isDone: (e) => const {
          'completed',
          'delivered',
          'cancelled',
        }.contains(e.status.toLowerCase()),
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
          merger.searchQuery.value = '';
          merger.statusFilter.value = CustomerOrderStatusFilter.all;
          merger.dateFilter.value = OrderDateFilter.all;
          merger.sortOrder.value = CustomerOrderSort.newest;
        },
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    DashboardOrderEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(CustomerOrderStrings.deleteDialogTitle),
        content: Text(CustomerOrderStrings.deleteDialogBody(entry.id)),
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

/// One row: a small market badge, then the exact same card that market's
/// own Orders screen already uses (`OrderSummaryCard` / `CosmeticOrderCard`)
/// — no new card design, just a tag distinguishing where each order is from.
class _DashboardOrderTile extends StatelessWidget {
  const _DashboardOrderTile({required this.entry});

  final DashboardOrderEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarketBadge(isFood: entry.isFood),
        const SizedBox(height: 6),
        entry.isFood
            ? OrderSummaryCard(order: entry.foodOrder)
            : CosmeticOrderCard(order: entry.cosmeticOrder),
      ],
    );
  }
}

class _MarketBadge extends StatelessWidget {
  const _MarketBadge({required this.isFood});

  final bool isFood;

  @override
  Widget build(BuildContext context) {
    final color = marketAccent(isFood ? 'food' : 'cosmetic');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFood
            ? MarketBrandStrings.foodTitle
            : MarketBrandStrings.cosmeticsTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
