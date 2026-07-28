// lib/screens/business/business_earnings_screen.dart
//
// Earnings tab for the business dashboard — mirrors the Analytics screen
// structure but focuses on revenue flow, payout status, and per-order detail.
//
// Sections (top → bottom):
//   Period selector  — scrollable ChoiceChips (Today / Week / Month / …)
//   Hero card        — net earnings figure with gradient background + trend
//   Breakdown card   — Gross → service fee → adjustments → Net
//   Payout card      — pending amount, paid out, next transfer date
//   Chart card       — daily/weekly net earnings bar chart
//   Transactions     — recent orders with individual earnings

import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_earnings_controller.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/constants/food/business_constants/business_analytics_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';

class BusinessEarningsScreen extends StatelessWidget {
  const BusinessEarningsScreen({super.key});

  // ── Palette ───────────────────────────────────────────────────────────────

  // ── Controller ────────────────────────────────────────────────────────────
  BusinessEarningsController get c => Get.find<BusinessEarningsController>();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray50,
      // Period selector is a fixed Column child (outside the scroll view) so
      // it stays pinned on screen — only the earnings content underneath
      // scrolls. Matches the fixed-header pattern used on the Menu/Orders/
      // Analytics tabs.
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            // Period chips — Obx so the selected chip updates reactively.
            child: Obx(() => _buildPeriodSelector()),
          ),
          Expanded(
            // Main content — single Obx rebuilds everything when the period
            // changes or the loading state toggles.
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
                    _buildHeroCard(data),
                    const SizedBox(height: 16),
                    _buildBreakdownCard(data),
                    const SizedBox(height: 16),
                    _buildPayoutCard(data),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: BusinessEarningsStrings.sectionNetEarnings,
                      child: _buildBarChart(data.chartBars),
                    ),
                    const SizedBox(height: 16),
                    _buildTransactionsCard(data.transactions),
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

  // ── Hero card ─────────────────────────────────────────────────────────────

  Widget _buildHeroCard(EarningsData data) {
    final periodLabel = c.selectedPeriod.value.label;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.successDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.successDark.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles for depth.
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content.
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: label + trend badge.
                Row(
                  children: [
                    Text(
                      BusinessEarningsStrings.heroLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    _trendBadge(data.trendPct),
                  ],
                ),
                const SizedBox(height: 10),
                // Big earnings figure.
                Text(
                  CurrencyFormatter.format(data.netEarnings),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Period label.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    periodLabel,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendBadge(double pct) {
    final isUp = pct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isUp ? AppColors.success : AppColors.error).withValues(
          alpha: 0.85,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: AppColors.white,
          ),
          const SizedBox(width: 3),
          Text(
            CurrencyFormatter.localizeDigits(
              '${pct.abs().toStringAsFixed(1)}%',
            ),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Breakdown card ────────────────────────────────────────────────────────

  Widget _buildBreakdownCard(EarningsData data) {
    final feePct = CurrencyFormatter.formatPercentPlain(
      data.serviceFeePct * 100,
    );

    return _buildCard(
      title: BusinessEarningsStrings.sectionBreakdown,
      child: Column(
        children: [
          _breakdownRow(
            label: BusinessEarningsStrings.grossRevenue,
            value: data.grossRevenue,
            isTotal: false,
          ),
          const SizedBox(height: 10),
          _breakdownRow(
            label: BusinessEarningsStrings.serviceFee(feePct),
            value: -data.serviceFee,
            isTotal: false,
          ),
          if (data.adjustments != 0) ...[
            const SizedBox(height: 10),
            _breakdownRow(
              label: BusinessEarningsStrings.refundsAdjustments,
              value: data.adjustments,
              isTotal: false,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.8),
          ),
          _breakdownRow(
            label: BusinessEarningsStrings.netEarnings,
            value: data.netEarnings,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow({
    required String label,
    required double value,
    required bool isTotal,
  }) {
    final isNegative = value < 0;

    final labelStyle = isTotal
        ? const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          )
        : TextStyle(
            fontSize: 13,
            color: isNegative ? AppColors.errorDark : AppColors.gray500,
          );

    final valueStyle = isTotal
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.successDark,
          )
        : TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isNegative ? AppColors.errorDark : AppColors.navy,
          );

    final displayValue = isNegative
        ? '− ${CurrencyFormatter.format(value.abs())}'
        : (isTotal
              ? '= ${CurrencyFormatter.format(value)}'
              : CurrencyFormatter.format(value));

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(displayValue, style: valueStyle),
      ],
    );
  }

  // ── Payout card ───────────────────────────────────────────────────────────

  Widget _buildPayoutCard(EarningsData data) {
    final hasPending = data.pendingPayout > 0;

    return _buildCard(
      title: BusinessEarningsStrings.sectionPayout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank account row.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.infoDark.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.infoDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BusinessEarningsStrings.bankAccount,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 11,
                    ),
                  ),
                  const Text(
                    '···· ···· ···· 4242',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Pending + paid out side by side.
          Row(
            children: [
              Expanded(
                child: _payoutStat(
                  label: BusinessEarningsStrings.pending,
                  value: CurrencyFormatter.format(data.pendingPayout),
                  valueColor: hasPending
                      ? AppColors.warningDeep
                      : AppColors.gray500,
                  icon: Icons.schedule_outlined,
                  iconColor: hasPending
                      ? AppColors.warningDeep
                      : AppColors.gray500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _payoutStat(
                  label: BusinessEarningsStrings.paidOut,
                  value: CurrencyFormatter.format(data.paidOut),
                  valueColor: AppColors.successDark,
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.successDark,
                ),
              ),
            ],
          ),
          // Next payout date banner — hidden when nothing is pending.
          if (hasPending && data.nextPayoutDate != '—') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.successDark.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: AppColors.successDark,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      BusinessEarningsStrings.nextPayoutOn(data.nextPayoutDate),
                      style: const TextStyle(
                        color: AppColors.successDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _payoutStat({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(color: AppColors.gray500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart ─────────────────────────────────────────────────────────────

  Widget _buildBarChart(List<EarningsBar> bars) {
    const maxBarHeight = 90.0;
    final maxVal = bars.map((b) => b.value).fold(0.0, max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final bar in bars)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Container(
                  height: maxVal > 0 ? (bar.value / maxVal) * maxBarHeight : 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: bar.value == maxVal
                        ? AppColors.successDark
                        : AppColors.successDark.withValues(alpha: 0.40),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  bar.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Transactions card ─────────────────────────────────────────────────────

  Widget _buildTransactionsCard(List<EarningsTransaction> transactions) {
    return _buildCard(
      title: BusinessEarningsStrings.sectionTransactions,
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            if (i > 0) const Divider(height: 16, thickness: 0.5),
            _buildTransactionRow(transactions[i]),
          ],
          const SizedBox(height: 4),
          // "View all" link — implement navigation when the full transaction
          // history screen is added.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                /* TODO: navigate to full transaction history */
              },
              icon: Text(
                BusinessEarningsStrings.viewAllTransactions,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.successDark,
                ),
              ),
              label: const Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.successDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(EarningsTransaction t) {
    final avatarColor = t.isPaid
        ? AppColors.successLight
        : AppColors.warningLight;
    final avatarTextColor = t.isPaid
        ? AppColors.successDark
        : AppColors.warningDeep;
    final badgeColor = t.isPaid
        ? AppColors.successLight
        : AppColors.warningLight;
    final badgeTextColor = t.isPaid
        ? AppColors.successDark
        : AppColors.warningDeep;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Customer initial avatar.
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
          child: Center(
            child: Text(
              t.customerName[0],
              style: TextStyle(
                color: avatarTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + offer + time.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.orderId,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                t.offerName,
                style: const TextStyle(color: AppColors.gray500, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                t.timeLabel,
                style: const TextStyle(color: AppColors.gray500, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Net amount + status badge.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${CurrencyFormatter.format(t.net)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.successDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t.isPaid
                    ? BusinessEarningsStrings.paidBadge
                    : BusinessEarningsStrings.pendingBadge,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────────

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
}
