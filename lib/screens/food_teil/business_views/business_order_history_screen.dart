import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_order_history_controller.dart';
import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:core/core.dart';
import 'package:food_app/screens/food_teil/business_views/business_order_detail_screen.dart';
import 'package:food_app/constants/food/business_constants/business_order_history_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BusinessOrderHistoryScreen extends StatefulWidget {
  const BusinessOrderHistoryScreen({super.key});

  @override
  State<BusinessOrderHistoryScreen> createState() =>
      _BusinessOrderHistoryScreenState();
}

class _BusinessOrderHistoryScreenState
    extends State<BusinessOrderHistoryScreen> {
  late final BusinessOrderHistoryController c;
  late final TextEditingController _searchCtrl;
  final ScrollController _scrollCtrl = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    c = Get.put(
      BusinessOrderHistoryController(OrderService(Get.find<ApiService>())),
    );
    _searchCtrl = TextEditingController();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    Get.delete<BusinessOrderHistoryController>();
    super.dispose();
  }

  // Auto-loads the next page a bit before the user hits the bottom, so the
  // list keeps filling itself while scrolling instead of requiring a tap on
  // the "Load more" button. The button stays as a fallback for short lists
  // that never produce enough scroll extent to trigger this listener.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      c.loadMore();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  //
  // Preset chips, summary banner and status chips are fixed Column children
  // (outside the scroll view) so they stay pinned on screen — only the order
  // list underneath scrolls. In landscape the banner switches to a compact
  // single-row layout so the fixed header never outgrows the available height
  // and the order list (in Expanded) still gets room to breathe.

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildPresetChips(context, isLandscape),
            Obx(() {
              final loadedCount = c.orders.length;
              if (c.isLoading.value || loadedCount == 0) {
                return const SizedBox.shrink();
              }
              return _SummaryBanner(
                totalOrders: c.totalItems.value,
                shownOrders: loadedCount,
                revenue: c.totalRevenue,
                completedCount: c.completedCount,
                cancelledCount: c.cancelledCount,
                isLandscape: isLandscape,
              );
            }),
            _buildStatusFilterChips(isLandscape),
            Expanded(
              child: Obx(() {
                final isLoading = c.isLoading.value;
                final hasError =
                    c.errorMessage.value.isNotEmpty && c.orders.isEmpty;
                final items = c.filteredOrders;
                final itemCount = isLoading || hasError || items.isEmpty
                    ? 1
                    : items.length + 1;

                return RefreshIndicator(
                  onRefresh: () async => c.refresh(),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                    itemCount: itemCount,
                    itemBuilder: (ctx, i) {
                      // Loading
                      if (isLoading) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      // Error
                      if (hasError) return _buildErrorState();

                      // Empty
                      if (items.isEmpty) return _buildEmptyState(context);

                      // Load-more sentinel
                      if (i == items.length) return _buildLoadMore();

                      // Order card
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          i == 0 ? 12 : 0,
                          12,
                          10,
                        ),
                        child: _HistoryOrderCard(order: items[i]),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: BusinessOrderHistoryStrings.searchHint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
              onChanged: (v) => c.searchQuery.value = v,
            )
          : Text(BusinessOrderHistoryStrings.title),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                c.searchQuery.value = '';
              }
            });
          },
        ),
      ],
    );
  }

  // ── Date preset chips ─────────────────────────────────────────────────────

  Widget _buildPresetChips(BuildContext context, bool isLandscape) {
    return Container(
      color: AppColors.card,
      padding: EdgeInsets.fromLTRB(
        12,
        isLandscape ? 6 : 10,
        12,
        isLandscape ? 6 : 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final current = c.preset.value;
          return Row(
            children: HistoryDatePreset.values.map((p) {
              final selected = current == p;
              final isCustom = p == HistoryDatePreset.custom;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                      isCustom ? _pickCustomRange(context) : c.selectPreset(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.gray100,
                      borderRadius: BorderRadius.circular(22),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.gray200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCustom) ...[
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 13,
                            color: selected
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: BusinessOrderHistoryStrings.selectCustomDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      c.setCustomRange(result.start, result.end.add(const Duration(days: 1)));
    }
  }

  // ── Status filter chips ───────────────────────────────────────────────────

  Widget _buildStatusFilterChips(bool isLandscape) {
    return Obx(() {
      final current = c.statusFilter.value;
      return Container(
        color: AppColors.card,
        padding: EdgeInsets.fromLTRB(
          12,
          isLandscape ? 4 : 6,
          12,
          isLandscape ? 6 : 10,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: HistoryStatusFilter.values.map((f) {
              final selected = current == f;
              final color = switch (f) {
                HistoryStatusFilter.all => AppColors.primary,
                HistoryStatusFilter.completed => AppColors.success,
                HistoryStatusFilter.cancelled => AppColors.error,
              };
              final icon = switch (f) {
                HistoryStatusFilter.all => Icons.all_inclusive_rounded,
                HistoryStatusFilter.completed => Icons.check_circle_rounded,
                HistoryStatusFilter.cancelled => Icons.cancel_rounded,
              };
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => c.statusFilter.value = f,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? color : AppColors.gray100,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: selected
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
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
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  // ── Error / empty states ─────────────────────────────────────────────────

  Widget _buildErrorState() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              c.errorMessage.value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            CustomDynamicButton(
              label: BusinessOrderHistoryStrings.retry,
              onPressed: c.refresh,
              icon: Icons.refresh_rounded,
              accentColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 36,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            BusinessOrderHistoryStrings.emptyTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            BusinessOrderHistoryStrings.emptySubtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Obx(() {
      if (c.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (!c.hasMore.value) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: CustomDynamicButton(
            label: BusinessOrderHistoryStrings.loadMore,
            onPressed: c.loadMore,
            variant: CustomButtonVariant.outlined,
            icon: Icons.expand_more_rounded,
            borderRadius: 22,
          ),
        ),
      );
    });
  }
}

// ── Summary banner ───────────────────────────────────────────────────────────
//
// Bold dark-to-green hero banner (navy → primary, gold revenue accent) in the
// spirit of UberEats/Too Good To Go earnings cards — the numbers a partner
// cares about most (orders, revenue, completed/cancelled) pop against a dark
// background instead of blending into a flat card. Fixed above the order
// list (not inside the scroll view). Switches to a compact single-row layout
// in landscape so the fixed header never eats into the scrollable list.

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.totalOrders,
    required this.shownOrders,
    required this.revenue,
    required this.completedCount,
    required this.cancelledCount,
    required this.isLandscape,
  });

  final int totalOrders;
  final int shownOrders;
  final double revenue;
  final int completedCount;
  final int cancelledCount;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, isLandscape ? 8 : 12, 12, 4),
      padding: EdgeInsets.fromLTRB(
        18,
        isLandscape ? 10 : 18,
        18,
        isLandscape ? 10 : 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative translucent icon — pure flair, ignored by layout.
            Positioned(
              right: -14,
              top: -18,
              child: Icon(
                Icons.storefront_rounded,
                size: isLandscape ? 72 : 108,
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),
            isLandscape ? _compactRow() : _heroLayout(),
          ],
        ),
      ),
    );
  }

  Widget _heroLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 13,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 5),
            Text(
              BusinessOrderHistoryStrings.summaryEyebrow.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BannerMetric(
                value: CurrencyFormatter.localizeDigits('$totalOrders'),
                label: BusinessOrderHistoryStrings.summaryOrders,
                alignEnd: false,
                valueColor: AppColors.white,
              ),
            ),
            Container(
              width: 1,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: AppColors.white.withValues(alpha: 0.25),
            ),
            _BannerMetric(
              value: CurrencyFormatter.round(revenue),
              label: BusinessOrderHistoryStrings.summaryRevenue,
              alignEnd: true,
              valueColor: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _BannerStatChip(
                icon: Icons.check_circle_rounded,
                count: completedCount,
                label: BusinessOrderHistoryStrings.summaryCompleted,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BannerStatChip(
                icon: Icons.cancel_rounded,
                count: cancelledCount,
                label: BusinessOrderHistoryStrings.summaryCancelled,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        if (shownOrders < totalOrders) ...[
          const SizedBox(height: 10),
          Text(
            BusinessOrderHistoryStrings.showingOf(shownOrders, totalOrders),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }

  // Single scrollable row used in landscape to keep the fixed header short.
  Widget _compactRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CompactStat(
            icon: Icons.receipt_long_rounded,
            value: CurrencyFormatter.localizeDigits('$totalOrders'),
            label: BusinessOrderHistoryStrings.summaryOrders,
            color: AppColors.white,
          ),
          _compactDivider(),
          _CompactStat(
            icon: Icons.payments_rounded,
            value: CurrencyFormatter.round(revenue),
            label: BusinessOrderHistoryStrings.summaryRevenue,
            color: AppColors.accent,
          ),
          _compactDivider(),
          _CompactStat(
            icon: Icons.check_circle_rounded,
            value: CurrencyFormatter.localizeDigits('$completedCount'),
            label: BusinessOrderHistoryStrings.summaryCompleted,
            color: AppColors.white,
          ),
          _compactDivider(),
          _CompactStat(
            icon: Icons.cancel_rounded,
            value: CurrencyFormatter.localizeDigits('$cancelledCount'),
            label: BusinessOrderHistoryStrings.summaryCancelled,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _compactDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.white.withValues(alpha: 0.2),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({
    required this.value,
    required this.label,
    required this.alignEnd,
    required this.valueColor,
  });

  final String value;
  final String label;
  final bool alignEnd;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _BannerStatChip extends StatelessWidget {
  const _BannerStatChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${CurrencyFormatter.localizeDigits('$count')} $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact icon + value + label group used by the landscape banner row.
class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ── History order card ────────────────────────────────────────────────────────

class _HistoryOrderCard extends StatelessWidget {
  const _HistoryOrderCard({required this.order});

  final OrderModel order;

  Color get _statusColor => switch (order.status) {
    'completed' || 'delivered' => AppColors.success,
    'cancelled' => AppColors.error,
    _ => AppColors.primary,
  };

  Color get _statusBg => switch (order.status) {
    'completed' || 'delivered' => AppColors.successLight,
    'cancelled' => AppColors.errorLight,
    _ => AppColors.primaryLight,
  };

  static final DateFormat _dateFormat = DateFormat('MMM d, HH:mm');

  @override
  Widget build(BuildContext context) {
    final customerName =
        '${order.user?.firstName ?? ''} ${order.user?.lastName ?? ''}'.trim();
    final displayName = customerName.isEmpty ? 'Guest' : customerName;

    final dt = order.createdAtDate?.toLocal();
    final dateStr = dt != null ? _dateFormat.format(dt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () => Get.to(() => BusinessOrderDetailScreen(order: order)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Left: order icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_rounded,
                    size: 20,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Center: order id, customer, items
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${CurrencyFormatter.localizeDigits(order.id)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.itemCountLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: status badge, price, date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(
                      label: order.statusLabel,
                      color: _statusColor,
                      bg: _statusBg,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(order.totalPriceValue),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
