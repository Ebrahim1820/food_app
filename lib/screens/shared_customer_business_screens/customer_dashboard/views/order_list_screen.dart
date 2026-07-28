// Generic customer order-history screen — sort/status/date filter chips and
// a paginated vertical list of the user's orders. The title/count now lives
// in the shell AppBar (see AppShellScreen._ordersSubtitle), not this body.
// Reusable across markets the same way FavoritesScreen<T> is: a market
// wiring layer (e.g. Food's OrderListScreen) extracts values/callbacks from
// its own order controller into an [OrderListConfig], and owns anything
// market-specific this screen has no business knowing about — the actual
// order controller, persistence, and the row widget itself (via
// [OrderListConfig.itemBuilder]).
//
// Swipe-to-delete is opt-in via [OrderListConfig.deleteConfig] — null (e.g.
// Cosmetic today) simply omits it, no placeholder shown.
//
// This file never imports a market model, market controller, or a market's
// translation keys — it only reads/writes the plain Rx fields and callbacks
// handed to it. `CustomerOrderSort`/`CustomerOrderStatusFilter`/
// `OrderDateFilter` and `MenuChipWidget` are already market-agnostic shared
// types, so they're used directly rather than re-abstracted.

import 'package:flutter/material.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/profile_and_orders/profile/views/dismiss_background_widget.dart';
import 'package:food_app/profile_and_orders/profile/views/menu_chip_widget.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/common/filter_chip_widget.dart';
import 'package:food_app/widgets/common/stale_banner.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:get/get.dart';

/// Bundles swipe-to-delete behavior for [OrderListScreen] — pass null to
/// [OrderListConfig.deleteConfig] to disable it entirely (no placeholder
/// shown, matches a market with no delete/cancel-by-swipe flow yet).
class OrderListDeleteConfig<T> {
  final bool Function(T order) canDelete;
  final Future<bool> Function(BuildContext context, T order) confirmDelete;
  final void Function(T order) onDelete;

  const OrderListDeleteConfig({
    required this.canDelete,
    required this.confirmDelete,
    required this.onDelete,
  });
}

/// Everything [OrderListScreen] needs to render one market's order history.
/// A market wires this up once (see Food's OrderListScreen) by pointing the
/// Rx fields at its own order controller and mapping its item model to a
/// row widget via [itemBuilder].
class OrderListConfig<T> {
  final RxList<T> rawOrders;

  /// Pure function of the current search/sort/status/date filter state onto
  /// [rawOrders] — called inside an `Obx`, so it re-runs whenever any filter
  /// or [rawOrders] itself changes.
  final List<T> Function(List<T> rawOrders) filterAndSort;

  /// Stable identity per order, e.g. `(o) => o.id` — used as the list key so
  /// ListView.builder never recycles an in-flight row's State onto a
  /// different order while scrolling.
  final Object Function(T order) keyOf;

  final RxBool isLoading;
  final RxBool isLoadingMore;
  final RxString errorMessage;
  final RxBool isFromCache;

  final RxString searchQuery;
  final Rx<CustomerOrderSort> sortOrder;
  final Rx<CustomerOrderStatusFilter> statusFilter;
  final Rx<OrderDateFilter> dateFilter;

  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  final Widget Function(T order) itemBuilder;
  final OrderListDeleteConfig<T>? deleteConfig;

  /// Splits the (already filtered/sorted) list into "Active" and "Done"
  /// sections instead of one flat list — true means the order is finished
  /// (completed/delivered/cancelled) and belongs under [doneSectionLabel].
  /// Null (the default) keeps the old flat, unsectioned list. There's no
  /// third "incoming" bucket here on purpose — unlike the business side's
  /// `OrderBucket`, a customer doesn't need pending split out from active;
  /// they only care "is this still happening, or is it over".
  final bool Function(T order)? isDone;
  final String? activeSectionLabel;
  final String? doneSectionLabel;

  // ── Copy ─────────────────────────────────────────────────────────────────
  final String sortNewestLabel;
  final String sortOldestLabel;
  final String Function(CustomerOrderSort sort) sortPriceLabel;
  final String filterTodayLabel;
  final String filterThisWeekLabel;

  final String emptyTitle;
  final String emptySubtitle;
  final String filteredEmptyTitle;
  final String filteredEmptySubtitle;
  final String clearFiltersButtonLabel;
  final String tryAgainLabel;
  final VoidCallback onClearFilters;

  const OrderListConfig({
    required this.rawOrders,
    required this.filterAndSort,
    required this.keyOf,
    required this.isLoading,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.isFromCache,
    required this.searchQuery,
    required this.sortOrder,
    required this.statusFilter,
    required this.dateFilter,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    this.deleteConfig,
    this.isDone,
    this.activeSectionLabel,
    this.doneSectionLabel,
    required this.sortNewestLabel,
    required this.sortOldestLabel,
    required this.sortPriceLabel,
    required this.filterTodayLabel,
    required this.filterThisWeekLabel,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.filteredEmptyTitle,
    required this.filteredEmptySubtitle,
    required this.clearFiltersButtonLabel,
    required this.tryAgainLabel,
    required this.onClearFilters,
  });
}

class OrderListScreen<T> extends StatefulWidget {
  final OrderListConfig<T> config;

  const OrderListScreen({super.key, required this.config});

  @override
  State<OrderListScreen<T>> createState() => _OrderListScreenState<T>();
}

class _OrderListScreenState<T> extends State<OrderListScreen<T>> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      widget.config.onLoadMore();
    }
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Column(
      children: [
        _FilterChips<T>(config: config),
        Obx(
          () => config.isFromCache.value
              ? StaleBanner(onRefresh: config.onRefresh)
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: _OrderList<T>(config: config, scrollCtrl: _scrollCtrl),
        ),
      ],
    );
  }
}

// ── Sort + status + date filter chips ────────────────────────────────────────

class _FilterChips<T> extends StatelessWidget {
  final OrderListConfig<T> config;
  const _FilterChips({required this.config});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sort = config.sortOrder.value;
      final isPriceActive =
          sort == CustomerOrderSort.priceHighLow ||
          sort == CustomerOrderSort.priceLowHigh;
      final priceLabel = config.sortPriceLabel(sort);
      final statusActive =
          config.statusFilter.value != CustomerOrderStatusFilter.all;

      return Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              FilterChipWidget(
                label: config.sortNewestLabel,
                selected: sort == CustomerOrderSort.newest,
                onTap: () => config.sortOrder.value = CustomerOrderSort.newest,
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: config.sortOldestLabel,
                selected: sort == CustomerOrderSort.oldest,
                onTap: () => config.sortOrder.value = CustomerOrderSort.oldest,
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: priceLabel,
                selected: isPriceActive,
                onTap: () => config.sortOrder.value =
                    sort == CustomerOrderSort.priceLowHigh
                    ? CustomerOrderSort.priceHighLow
                    : CustomerOrderSort.priceLowHigh,
              ),
              const SizedBox(width: 8),
              MenuChipWidget<CustomerOrderStatusFilter>(
                label: statusActive
                    ? config.statusFilter.value.label
                    : CustomerOrderStatusFilter.all.label,
                isActive: statusActive,
                value: config.statusFilter.value,
                options: CustomerOrderStatusFilter.values,
                labelOf: (s) => s.label,
                onSelected: (v) => config.statusFilter.value = v,
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: config.filterTodayLabel,
                selected: config.dateFilter.value == OrderDateFilter.today,
                onTap: () => config.dateFilter.value =
                    config.dateFilter.value == OrderDateFilter.today
                    ? OrderDateFilter.all
                    : OrderDateFilter.today,
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: config.filterThisWeekLabel,
                selected: config.dateFilter.value == OrderDateFilter.thisWeek,
                onTap: () => config.dateFilter.value =
                    config.dateFilter.value == OrderDateFilter.thisWeek
                    ? OrderDateFilter.all
                    : OrderDateFilter.thisWeek,
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Order list body ──────────────────────────────────────────────────────────

class _OrderList<T> extends StatelessWidget {
  final OrderListConfig<T> config;
  final ScrollController scrollCtrl;
  const _OrderList({required this.config, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (config.isLoading.value && config.rawOrders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (config.errorMessage.value.isNotEmpty && config.rawOrders.isEmpty) {
        return ErrorRetryWidget(
          message: config.errorMessage.value,
          onRetry: config.onRefresh,
        );
      }

      final orders = config.filterAndSort(config.rawOrders.toList());
      if (orders.isEmpty) return _EmptyState<T>(config: config);

      final isLoadingMore = config.isLoadingMore.value;
      final rows = _buildRows(orders);

      return RefreshIndicator(
        onRefresh: config.onRefresh,
        child: ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(12),
          itemCount: rows.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == rows.length) return const _LoadMoreSpinner();

            final row = rows[index];
            if (row.header != null) {
              return _SectionHeader(
                label: row.header!,
                topPadding: index == 0 ? 4 : 20,
                showDivider: row.showDivider,
              );
            }

            final order = row.order as T;
            final key = ValueKey(config.keyOf(order));
            final del = config.deleteConfig;
            if (del == null || !del.canDelete(order)) {
              return KeyedSubtree(key: key, child: config.itemBuilder(order));
            }
            return Dismissible(
              key: key,
              direction: DismissDirection.horizontal,
              background: const DismissBackgroundWidget(),
              secondaryBackground: const DismissBackgroundWidget(
                alignment: Alignment.centerRight,
              ),
              confirmDismiss: (_) => del.confirmDelete(context, order),
              onDismissed: (_) => del.onDelete(order),
              child: config.itemBuilder(order),
            );
          },
        ),
      );
    });
  }

  /// Flattens [orders] into header + order rows for [ListView.builder].
  /// Without [OrderListConfig.isDone] this is just every order in order —
  /// no headers, same as before sectioning existed.
  List<_Row<T>> _buildRows(List<T> orders) {
    final isDone = config.isDone;
    if (isDone == null) {
      return orders.map((o) => _Row<T>.order(o)).toList();
    }
    final active = orders.where((o) => !isDone(o)).toList();
    final done = orders.where(isDone).toList();
    return [
      if (active.isNotEmpty) _Row<T>.header(config.activeSectionLabel ?? ''),
      ...active.map((o) => _Row<T>.order(o)),
      // The divider only makes sense between two sections — never above the
      // very first header, so it's tied to the Done header specifically.
      if (done.isNotEmpty)
        _Row<T>.header(
          config.doneSectionLabel ?? '',
          showDivider: active.isNotEmpty,
        ),
      ...done.map((o) => _Row<T>.order(o)),
    ];
  }
}

/// One row in the (optionally sectioned) order list — either a section
/// header or an order. Never both.
class _Row<T> {
  final String? header;
  final T? order;
  final bool showDivider;
  const _Row.header(this.header, {this.showDivider = false}) : order = null;
  const _Row.order(this.order) : header = null, showDivider = false;
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final double topPadding;
  final bool showDivider;
  const _SectionHeader({
    required this.label,
    required this.topPadding,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topPadding, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDivider) ...[
            const Divider(color: AppColors.gray300, thickness: 1.5, height: 1),
            const SizedBox(height: 16),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreSpinner extends StatelessWidget {
  const _LoadMoreSpinner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState<T> extends StatelessWidget {
  final OrderListConfig<T> config;
  const _EmptyState({required this.config});

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        config.searchQuery.value.isNotEmpty ||
        config.statusFilter.value != CustomerOrderStatusFilter.all ||
        config.dateFilter.value != OrderDateFilter.all;

    return EmptyStateWidget(
      icon: hasFilters ? Icons.filter_list_off : Icons.shopping_bag_outlined,
      title: hasFilters ? config.filteredEmptyTitle : config.emptyTitle,
      subtitle: hasFilters
          ? config.filteredEmptySubtitle
          : config.emptySubtitle,
      action: hasFilters
          ? CustomDynamicButton(
              variant: CustomButtonVariant.text,
              label: config.clearFiltersButtonLabel,
              onPressed: config.onClearFilters,
            )
          // No filters active — an empty list here means either the
          // customer genuinely has no orders yet, or the fetch silently
          // came back empty. Offer a manual refresh either way instead of
          // a dead-end message.
          : CustomDynamicButton(
              variant: CustomButtonVariant.outlined,
              icon: Icons.refresh_rounded,
              label: config.tryAgainLabel,
              onPressed: () => config.onRefresh(),
            ),
    );
  }
}
