// lib/screens/business/business_orders_screen.dart
//
// Business partner's order management screen.
// Three tabs (New / Active / Done) with live search and filter chips.

import 'package:flutter/material.dart';
import 'package:food_app/constants/food/business_constants/business_order_history_strings.dart';
import 'package:food_app/constants/food/business_constants/business_order_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_order_controller.dart';
import 'package:models/models.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/screens/food_teil/business_views/business_order_detail_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_order_history_screen.dart';
import 'package:food_app/widgets/common/confirm_dialog.dart';
import 'package:food_app/widgets/common/stale_banner.dart';
import 'package:food_app/screens/food_teil/business_views/business_empty_orders.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/screens/food_teil/business_views/business_order_card.dart';
import 'package:get/get.dart';

/// The Orders tab for a business partner.
///
/// Layout:
///   AppBar  ← title or inline search field; TabBar in bottom
///   └─ thin filter chips row  ← sort + date chips, no search field
///   └─ TabBarView             ← New / Active / Done lists
///
/// Done tab has its own compact single-row bar (live indicator + status chips
/// + history shortcut) instead of the two-row banner + chips used before.
class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen>
    with SingleTickerProviderStateMixin {
  // ── Controller & local UI state ──────────────────────────────────────────

  final BusinessOrderController controller =
      Get.find<BusinessOrderController>();

  late final TabController _tabs = TabController(length: 3, vsync: this);

  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchOrders();
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Thin chips-only filter row (sort + date). Search is in the AppBar.
            Obx(() => _filterChipsBar()),

            Obx(
              () => controller.isFromCache.value
                  ? StaleBanner(onRefresh: controller.fetchOrders)
                  : const SizedBox.shrink(),
            ),

            // TabBarView lives OUTSIDE Obx so RefreshIndicator is never
            // recreated when reactive state changes mid-refresh.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TabBarView(
                    controller: _tabs,
                    children: [
                      _list(OrderBucket.incoming),
                      _list(OrderBucket.active),
                      _doneTab(),
                    ],
                  ),
                  // Overlay: initial-load spinner / error (only when list empty).
                  Obx(() {
                    if (controller.isLoading.value &&
                        controller.orders.isEmpty) {
                      return const ColoredBox(
                        color: AppColors.white,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (controller.errorMessage.value.isNotEmpty &&
                        controller.orders.isEmpty) {
                      return ColoredBox(
                        color: AppColors.white,
                        child: _errorView(context),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: BusinessOrdersScreenStrings.searchHint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
              onChanged: (v) => controller.searchQuery.value = v,
            )
          : Text(BusinessOrdersScreenStrings.appBarTitle),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                controller.searchQuery.value = '';
              }
            });
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          final newCount = controller
              .filteredForBucket(OrderBucket.incoming)
              .length;
          final activeCount = controller
              .filteredForBucket(OrderBucket.active)
              .length;
          final doneCount = controller
              .filteredForBucket(OrderBucket.done)
              .length;
          return TabBar(
            controller: _tabs,
            tabs: [
              _countTab(
                BusinessOrdersScreenStrings.tabNew,
                newCount,
                AppColors.warning,
              ),
              _countTab(
                BusinessOrdersScreenStrings.tabActive,
                activeCount,
                AppColors.primary,
              ),
              _countTab(
                BusinessOrdersScreenStrings.tabDone,
                doneCount,
                AppColors.gray400,
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Shared filter chips bar (all tabs) ────────────────────────────────────

  Widget _filterChipsBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(
              label: BusinessOrdersScreenStrings.filterOldestFirst,
              selected: controller.sortOrder.value == OrderSortOrder.oldest,
              onTap: () => controller.sortOrder.value =
                  controller.sortOrder.value == OrderSortOrder.oldest
                  ? OrderSortOrder.newest
                  : OrderSortOrder.oldest,
            ),
            const SizedBox(width: 6),
            _chip(
              label: BusinessOrdersScreenStrings.filterToday,
              selected: controller.dateFilter.value == OrderDateFilter.today,
              onTap: () => controller.dateFilter.value =
                  controller.dateFilter.value == OrderDateFilter.today
                  ? OrderDateFilter.all
                  : OrderDateFilter.today,
            ),
            const SizedBox(width: 6),
            _chip(
              label: BusinessOrdersScreenStrings.filterThisWeek,
              selected: controller.dateFilter.value == OrderDateFilter.thisWeek,
              onTap: () => controller.dateFilter.value =
                  controller.dateFilter.value == OrderDateFilter.thisWeek
                  ? OrderDateFilter.all
                  : OrderDateFilter.thisWeek,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Tab list ─────────────────────────────────────────────────────────────

  Widget _list(OrderBucket bucket) {
    return RefreshIndicator(
      onRefresh: controller.fetchOrders,
      child: Obx(() {
        final orders = controller.filteredForBucket(bucket);

        if (orders.isEmpty) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: BusinessEmptyOrders(bucket: bucket),
              ),
            ],
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: BusinessOrderCard(
                order: o,
                onTap: () => Get.to(() => BusinessOrderDetailScreen(order: o)),
                onAccept: () {
                  controller.accept(o);
                  _tabs.animateTo(1);
                },
                onReject: () {
                  controller.reject(o);
                  _tabs.animateTo(2);
                },
                onAdvance: () {
                  final next = _nextStatus(o);
                  controller.updateStatus(o, next);
                  const doneBound = {'completed', 'delivered', 'cancelled'};
                  if (doneBound.contains(next)) _tabs.animateTo(2);
                },
                onBack: () => controller.moveBack(o),
                onCancel: () => _confirmCancel(o),
              ),
            );
          },
        );
      }),
    );
  }

  // ── Done tab ─────────────────────────────────────────────────────────────

  Widget _doneTab() {
    return Column(
      children: [
        // Single compact row: live indicator + status chips + history button.
        Obx(() => _doneCompactBar()),
        Expanded(child: _list(OrderBucket.done)),
      ],
    );
  }

  /// One row that replaces the old two-row live banner + status filter bar.
  ///
  ///  🔴 Live  |  [All 12]  [Completed 9]  [Cancelled 3]  …  [📅]
  Widget _doneCompactBar() {
    final counts = controller.doneBucketCounts;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 4, 7),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Row(
        children: [
          // Live indicator dot
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            BusinessOrderHistoryStrings.doneTabLiveLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          // Thin divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 16,
            color: AppColors.gray200,
          ),
          // Status chips with counts
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: DoneOrderFilter.values.map((f) {
                  final selected = controller.doneStatusFilter.value == f;
                  final count = counts[f] ?? 0;
                  final color = switch (f) {
                    DoneOrderFilter.all => AppColors.primary,
                    DoneOrderFilter.completed => AppColors.success,
                    DoneOrderFilter.cancelled => AppColors.error,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => controller.doneStatusFilter.value = f,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? color : AppColors.gray100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.white.withValues(alpha: 0.25)
                                      : color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  CurrencyFormatter.localizeDigits('$count'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? AppColors.white : color,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // History icon button
          IconButton(
            onPressed: () => Get.to(() => const BusinessOrderHistoryScreen()),
            icon: const Icon(Icons.history_rounded),
            color: AppColors.primary,
            iconSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: BusinessOrderHistoryStrings.historyButton,
          ),
        ],
      ),
    );
  }

  // ── Error view ───────────────────────────────────────────────────────────

  Widget _errorView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(BusinessOrdersScreenStrings.errorCouldNotLoad),
          const SizedBox(height: 12),
          CustomDynamicButton(
            label: BusinessOrdersScreenStrings.retryButton,
            onPressed: controller.fetchOrders,
            variant: CustomButtonVariant.outlined,
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Tab _countTab(String label, int count, Color badgeColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                CurrencyFormatter.localizeDigits('$count'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _nextStatus(OrderModel o) =>
      OrderStatusEnums.fromValue(o.status).next?.value ?? o.status;

  Future<void> _confirmCancel(OrderModel o) async {
    final ok = await ConfirmDialog.show(
      context,
      icon: Icons.cancel_outlined,
      title: BusinessOrdersScreenStrings.cancelDialogTitle,
      subtitle: '#${CurrencyFormatter.localizeDigits(o.id)}',
      body: BusinessOrdersScreenStrings.cancelDialogBody(
        CurrencyFormatter.localizeDigits(o.id),
      ),
      confirmLabel: BusinessOrdersScreenStrings.cancelDialogConfirm,
      cancelLabel: BusinessOrdersScreenStrings.cancelDialogKeep,
    );
    if (ok == true) {
      controller.cancel(o);
      _tabs.animateTo(2);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}
