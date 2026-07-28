// lib/controllers/business_analytics_controller.dart
//
// Drives the Analytics tab in the business dashboard.
// Data models are defined here (analytics-only — no extra files needed).
// Currently uses mock data. Replace each switch arm in [currentData] with a
// real API call when the backend endpoint is ready.

import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:get/get.dart';

// ── Analytics data models ─────────────────────────────────────────────────────

/// One bar in the revenue chart (label + value in currency units).
class ChartBar {
  const ChartBar(this.label, this.value);

  /// X-axis label (e.g. "Mon", "10am", "Wk 1").
  final String label;

  /// Revenue value used to determine bar height proportionally.
  final double value;
}

/// Statistics for one of the top-performing offers in the period.
class TopOfferStat {
  const TopOfferStat({
    required this.name,
    required this.category,
    required this.orders,
    required this.revenue,
  });

  final String name;
  final String category;
  final int orders;
  final double revenue;
}

/// Order count for a single lifecycle status (used in the breakdown bar).
class StatusStat {
  const StatusStat({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

/// All statistics for one analytics period.
class AnalyticsData {
  const AnalyticsData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.completionRate,
    required this.chartBars,
    required this.topOffers,
    required this.statusStats,
  });

  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;

  /// Fraction of orders that reached "completed" (0.0 – 1.0).
  final double completionRate;

  final List<ChartBar> chartBars;
  final List<TopOfferStat> topOffers;
  final List<StatusStat> statusStats;
}

// ── Controller ────────────────────────────────────────────────────────────────

/// Manages state for [BusinessAnalyticsScreen].
///
/// [currentData] uses an exhaustive switch on [AnalyticsPeriod] — Dart will
/// produce a compile-time error if a new enum value is added without a
/// matching data case, making it impossible to get a null / missing-key crash.
class BusinessAnalyticsController extends GetxController {
  // ── Reactive state ────────────────────────────────────────────────────────

  /// Currently selected time range. Defaults to "This Week".
  final selectedPeriod = AnalyticsPeriod.week.obs;

  /// True while a period transition is in progress (shows a spinner).
  final isLoading = false.obs;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Returns the [AnalyticsData] for the active period via an exhaustive
  /// switch — no map lookup, no null, no hot-reload type mismatch possible.
  AnalyticsData get currentData => switch (selectedPeriod.value) {
    AnalyticsPeriod.today => _today,
    AnalyticsPeriod.week => _week,
    AnalyticsPeriod.month => _month,
    AnalyticsPeriod.lastMonth => _lastMonth,
    AnalyticsPeriod.lastThreeMonths => _lastThreeMonths,
  };

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Switches to [period] with a brief loading state that simulates an API
  /// call. Replace the Future.delayed with a real service call when ready.
  Future<void> selectPeriod(AnalyticsPeriod period) async {
    if (selectedPeriod.value == period) return;
    isLoading.value = true;
    selectedPeriod.value = period;
    await Future.delayed(const Duration(milliseconds: 350));
    isLoading.value = false;
  }

  // ── Mock datasets (static const — allocated once, never null) ─────────────
  // Each dataset is a separate named constant so the switch above can return
  // it directly. 'static const' means Dart allocates each object once at
  // compile time and reuses it — zero allocation on every rebuild.

  static const _today = AnalyticsData(
    totalRevenue: 284.0,
    totalOrders: 12,
    avgOrderValue: 23.67,
    completionRate: 0.917,
    chartBars: [
      ChartBar('8am', 18),
      ChartBar('10am', 54),
      ChartBar('12pm', 96),
      ChartBar('2pm', 72),
      ChartBar('4pm', 44),
      ChartBar('6pm', 0),
    ],
    topOffers: [
      TopOfferStat(
        name: 'Bakery surprise bag',
        category: 'bakery',
        orders: 5,
        revenue: 49.75,
      ),
      TopOfferStat(
        name: 'Meal of the day',
        category: 'meal',
        orders: 4,
        revenue: 79.80,
      ),
      TopOfferStat(
        name: 'Dessert box',
        category: 'dessert',
        orders: 3,
        revenue: 29.85,
      ),
    ],
    statusStats: [
      StatusStat(label: 'Completed', count: 11, color: AppColors.successDark),
      StatusStat(label: 'Cancelled', count: 1, color: AppColors.errorDark),
    ],
  );

  static const _week = AnalyticsData(
    totalRevenue: 1284.0,
    totalOrders: 47,
    avgOrderValue: 27.30,
    completionRate: 0.894,
    chartBars: [
      ChartBar('Mon', 142),
      ChartBar('Tue', 198),
      ChartBar('Wed', 175),
      ChartBar('Thu', 234),
      ChartBar('Fri', 284),
      ChartBar('Sat', 164),
      ChartBar('Sun', 87),
    ],
    topOffers: [
      TopOfferStat(
        name: 'Bakery surprise bag',
        category: 'bakery',
        orders: 18,
        revenue: 179.10,
      ),
      TopOfferStat(
        name: 'Meal of the day',
        category: 'meal',
        orders: 14,
        revenue: 279.30,
      ),
      TopOfferStat(
        name: 'Veggie pack',
        category: 'vegetables',
        orders: 9,
        revenue: 89.10,
      ),
      TopOfferStat(
        name: 'Dessert box',
        category: 'dessert',
        orders: 6,
        revenue: 59.70,
      ),
    ],
    statusStats: [
      StatusStat(label: 'Completed', count: 42, color: AppColors.successDark),
      StatusStat(label: 'Confirmed', count: 3, color: AppColors.infoDark),
      StatusStat(label: 'Cancelled', count: 2, color: AppColors.errorDark),
    ],
  );

  static const _month = AnalyticsData(
    totalRevenue: 4820.0,
    totalOrders: 176,
    avgOrderValue: 27.39,
    completionRate: 0.881,
    chartBars: [
      ChartBar('Wk 1', 980),
      ChartBar('Wk 2', 1240),
      ChartBar('Wk 3', 1580),
      ChartBar('Wk 4', 1020),
    ],
    topOffers: [
      TopOfferStat(
        name: 'Bakery surprise bag',
        category: 'bakery',
        orders: 64,
        revenue: 636.16,
      ),
      TopOfferStat(
        name: 'Meal of the day',
        category: 'meal',
        orders: 52,
        revenue: 1038.48,
      ),
      TopOfferStat(
        name: 'Veggie pack',
        category: 'vegetables',
        orders: 34,
        revenue: 336.66,
      ),
      TopOfferStat(
        name: 'Dessert box',
        category: 'dessert',
        orders: 26,
        revenue: 258.74,
      ),
    ],
    statusStats: [
      StatusStat(label: 'Completed', count: 155, color: AppColors.successDark),
      StatusStat(label: 'Confirmed', count: 11, color: AppColors.infoDark),
      StatusStat(label: 'Pending', count: 3, color: AppColors.warningDeep),
      StatusStat(label: 'Cancelled', count: 7, color: AppColors.errorDark),
    ],
  );

  static const _lastMonth = AnalyticsData(
    totalRevenue: 4210.0,
    totalOrders: 158,
    avgOrderValue: 26.65,
    completionRate: 0.873,
    chartBars: [
      ChartBar('Wk 1', 870),
      ChartBar('Wk 2', 1120),
      ChartBar('Wk 3', 940),
      ChartBar('Wk 4', 1280),
    ],
    topOffers: [
      TopOfferStat(
        name: 'Meal of the day',
        category: 'meal',
        orders: 58,
        revenue: 1158.42,
      ),
      TopOfferStat(
        name: 'Bakery surprise bag',
        category: 'bakery',
        orders: 47,
        revenue: 467.53,
      ),
      TopOfferStat(
        name: 'Veggie pack',
        category: 'vegetables',
        orders: 31,
        revenue: 306.69,
      ),
      TopOfferStat(
        name: 'Dessert box',
        category: 'dessert',
        orders: 22,
        revenue: 218.78,
      ),
    ],
    statusStats: [
      StatusStat(label: 'Completed', count: 138, color: AppColors.successDark),
      StatusStat(label: 'Confirmed', count: 8, color: AppColors.infoDark),
      StatusStat(label: 'Pending', count: 5, color: AppColors.warningDeep),
      StatusStat(label: 'Cancelled', count: 7, color: AppColors.errorDark),
    ],
  );

  static const _lastThreeMonths = AnalyticsData(
    totalRevenue: 13650.0,
    totalOrders: 497,
    avgOrderValue: 27.46,
    completionRate: 0.876,
    // Three bars — one per month — since weekly bars would be unreadable at 12+.
    chartBars: [
      ChartBar('Month 1', 4210),
      ChartBar('Month 2', 4820),
      ChartBar('Month 3', 4620),
    ],
    topOffers: [
      TopOfferStat(
        name: 'Meal of the day',
        category: 'meal',
        orders: 168,
        revenue: 3355.32,
      ),
      TopOfferStat(
        name: 'Bakery surprise bag',
        category: 'bakery',
        orders: 152,
        revenue: 1511.44,
      ),
      TopOfferStat(
        name: 'Veggie pack',
        category: 'vegetables',
        orders: 98,
        revenue: 970.02,
      ),
      TopOfferStat(
        name: 'Dessert box',
        category: 'dessert',
        orders: 79,
        revenue: 785.21,
      ),
    ],
    statusStats: [
      StatusStat(label: 'Completed', count: 435, color: AppColors.successDark),
      StatusStat(label: 'Confirmed', count: 28, color: AppColors.infoDark),
      StatusStat(label: 'Pending', count: 7, color: AppColors.warningDeep),
      StatusStat(label: 'Cancelled', count: 27, color: AppColors.errorDark),
    ],
  );
}
