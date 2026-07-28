// lib/screens/business/business_analytics_screen.dart
//
// Analytics tab for the business dashboard.
// StatelessWidget — all state and data live in BusinessAnalyticsController.

import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_analytics_controller.dart';
import 'package:models/models.dart';
import 'package:food_app/constants/food/business_constants/business_analytics_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';

/// Displays revenue, order, and offer performance statistics for the selected
/// time period (Today / This Week / This Month).
///
/// Layout (top → bottom):
///   Period selector   — ChoiceChips to switch the time range
///   KPI cards         — Revenue · Orders · Avg order · Completion rate
///   Revenue chart     — Custom bar chart built from Container widgets
///   Top offers        — Ranked list of best-performing offers
///   Orders by status  — Horizontal progress bars per status
///
/// Lives inside the dashboard's [IndexedStack] — no Scaffold/AppBar of its own.
class BusinessAnalyticsScreen extends StatelessWidget {
  const BusinessAnalyticsScreen({super.key});

  // ── Palette ───────────────────────────────────────────────────────────────

  // ── Controller ────────────────────────────────────────────────────────────

  // StatelessWidget accesses the controller via Get.find every build cycle.
  // GetX returns the same singleton, so this is safe and cheap.
  BusinessAnalyticsController get c => Get.find<BusinessAnalyticsController>();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray50,
      // Period selector is a fixed Column child (outside the scroll view) so
      // it stays pinned on screen — only the stats content underneath
      // scrolls. Matches the fixed-header pattern used on the Menu/Orders
      // tabs.
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            // Wrapped in Obx so the selected chip highlights reactively.
            child: Obx(() => _buildPeriodSelector()),
          ),
          Expanded(
            // Single Obx: rebuilds the entire stats view when the period
            // changes or loading state toggles.
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = c.currentData;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── KPI metric cards ──────────────────────────────────
                    _buildKpiGrid(data),
                    const SizedBox(height: 24),

                    // ── Revenue bar chart ───────────────────────────────────
                    _buildCard(
                      title: BusinessAnalyticsStrings.sectionRevenue,
                      child: _buildBarChart(data.chartBars),
                    ),
                    const SizedBox(height: 16),

                    // ── Top offers list ─────────────────────────────────────
                    _buildCard(
                      title: BusinessAnalyticsStrings.sectionTopOffers,
                      child: _buildTopOffers(data.topOffers),
                    ),
                    const SizedBox(height: 16),

                    // ── Orders by status ────────────────────────────────────
                    _buildCard(
                      title: BusinessAnalyticsStrings.sectionOrdersByStatus,
                      child: _buildStatusBreakdown(data.statusStats),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Period selector ───────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final period in AnalyticsPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(period.label),
                selected: c.selectedPeriod.value == period,
                onSelected: (_) => c.selectPeriod(period),
              ),
            ),
        ],
      ),
    );
  }

  // ── KPI cards ─────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(AnalyticsData data) {
    final cards = [
      (
        label: BusinessAnalyticsStrings.kpiRevenue,
        value: CurrencyFormatter.round(data.totalRevenue),
        icon: Icons.payments_outlined,
        color: AppColors.successDark,
      ),
      (
        label: BusinessAnalyticsStrings.kpiOrders,
        value: CurrencyFormatter.localizeDigits('${data.totalOrders}'),
        icon: Icons.receipt_long_outlined,
        color: AppColors.infoDark,
      ),
      (
        label: BusinessAnalyticsStrings.kpiAvgOrder,
        value: CurrencyFormatter.format(data.avgOrderValue),
        icon: Icons.trending_up,
        color: AppColors.purple,
      ),
      (
        label: BusinessAnalyticsStrings.kpiCompletion,
        value: CurrencyFormatter.formatPercentPlain(data.completionRate * 100),
        icon: Icons.check_circle_outline,
        color: AppColors.warningDeep,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: cards
          .map(
            (c) => _buildKpiCard(
              label: c.label,
              value: c.value,
              icon: c.icon,
              color: c.color,
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon badge.
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          // Big value.
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          // Label below the value.
          Text(
            label,
            style: const TextStyle(color: AppColors.gray600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────────

  /// White card with a bold title and arbitrary [child] content below.
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── Revenue bar chart ─────────────────────────────────────────────────────

  /// Draws a simple bar chart using proportionally-sized Containers.
  /// No external chart package needed.
  Widget _buildBarChart(List<ChartBar> bars) {
    const maxBarHeight = 90.0;
    final maxVal = bars.map((b) => b.value).fold(0.0, max);

    // No outer SizedBox with a fixed height — the Row sizes itself to the
    // tallest column. Each column uses mainAxisSize.min so it only takes the
    // height it needs and can never overflow its parent.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final bar in bars)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // shrinks to content, no overflow
              children: [
                // Value label shown only above the tallest bar.
                SizedBox(
                  height: 16,
                  child: bar.value == maxVal && maxVal > 0
                      ? Text(
                          CurrencyFormatter.compact(bar.value),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.successDark,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : null,
                ),
                const SizedBox(height: 2),
                // The bar — height is proportional to the maximum value.
                Container(
                  height: maxVal > 0 ? (bar.value / maxVal) * maxBarHeight : 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: bar.value == maxVal
                        ? AppColors.successDark
                        : AppColors.successDark.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // X-axis label.
                Text(
                  bar.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Top offers ────────────────────────────────────────────────────────────

  Widget _buildTopOffers(List<TopOfferStat> offers) {
    return Column(
      children: [
        for (int i = 0; i < offers.length; i++) ...[
          if (i > 0) const Divider(height: 16, thickness: 0.5, indent: 40),
          _buildOfferRow(rank: i + 1, stat: offers[i]),
        ],
      ],
    );
  }

  Widget _buildOfferRow({required int rank, required TopOfferStat stat}) {
    return Row(
      children: [
        // Rank badge.
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.successDark.withValues(alpha: 0.12)
                : AppColors.gray100,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: rank == 1 ? AppColors.successDark : AppColors.gray600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Name + category.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.navy,
                ),
              ),
              Text(
                _prettyCategory(stat.category),
                style: const TextStyle(fontSize: 11, color: AppColors.gray600),
              ),
            ],
          ),
        ),
        // Orders + revenue.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              BusinessAnalyticsStrings.ordersCount(stat.orders),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.navy,
              ),
            ),
            Text(
              CurrencyFormatter.format(stat.revenue),
              style: const TextStyle(fontSize: 11, color: AppColors.gray600),
            ),
          ],
        ),
      ],
    );
  }

  // ── Status breakdown ──────────────────────────────────────────────────────

  Widget _buildStatusBreakdown(List<StatusStat> stats) {
    final total = stats.fold(0, (sum, s) => sum + s.count);

    return Column(
      children: [
        for (final stat in stats) ...[
          _buildStatusBar(stat: stat, total: total),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStatusBar({required StatusStat stat, required int total}) {
    final ratio = total > 0 ? stat.count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Colour dot.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: stat.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stat.label,
                style: const TextStyle(fontSize: 13, color: AppColors.navy),
              ),
            ),
            Text(
              CurrencyFormatter.localizeDigits('${stat.count}'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${CurrencyFormatter.formatPercentPlain(ratio * 100)})',
              style: const TextStyle(fontSize: 11, color: AppColors.gray600),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Progress bar.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: stat.color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation(stat.color),
          ),
        ),
      ],
    );
  }

  // ── Formatting helpers ────────────────────────────────────────────────────

  String _prettyCategory(String cat) => cat
      .replaceAll('_', ' ')
      .replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());
}
