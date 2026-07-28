// lib/controllers/business_earnings_controller.dart
//
// Drives the Earnings tab in the business dashboard.
// Mirrors the pattern used in BusinessAnalyticsController:
//   • exhaustive switch on AnalyticsPeriod — no map lookup, no null
//   • static const datasets — allocated once at compile time
// Replace Future.delayed + mock data with a real payout-API call when ready.

import 'package:models/models.dart';
import 'package:get/get.dart';

// ── Data models ───────────────────────────────────────────────────────────────

/// One bar in the daily/weekly earnings chart.
class EarningsBar {
  const EarningsBar(this.label, this.value);

  /// X-axis label (e.g. "Mon", "Wk 1", "Month 1").
  final String label;

  /// Net earnings value used to determine proportional bar height.
  final double value;
}

/// A single completed order that contributed to earnings in the period.
class EarningsTransaction {
  const EarningsTransaction({
    required this.orderId,
    required this.customerName,
    required this.offerName,
    required this.gross,
    required this.fee,
    required this.net,
    required this.isPaid,
    required this.timeLabel,
  });

  /// e.g. "#1043"
  final String orderId;
  final String customerName;
  final String offerName;

  /// Full order value before the platform fee is deducted.
  final double gross;

  /// Platform service fee (gross × serviceFeePct).
  final double fee;

  /// What the business actually earns for this order (gross − fee).
  final double net;

  /// true = already included in a completed payout transfer.
  final bool isPaid;

  /// Human-readable timestamp shown in the transaction row.
  final String timeLabel;
}

/// All earnings statistics for one time period.
class EarningsData {
  const EarningsData({
    required this.grossRevenue,
    required this.serviceFee,
    required this.serviceFeePct,
    required this.adjustments,
    required this.netEarnings,
    required this.trendPct,
    required this.pendingPayout,
    required this.paidOut,
    required this.nextPayoutDate,
    required this.chartBars,
    required this.transactions,
  });

  /// Sum of all order values before deductions.
  final double grossRevenue;

  /// Platform commission deducted from gross (gross × serviceFeePct).
  final double serviceFee;

  /// Commission rate as a fraction, e.g. 0.15 for 15%.
  final double serviceFeePct;

  /// Refunds and manual corrections — negative means money back to customers.
  final double adjustments;

  /// Gross − serviceFee + adjustments = what the business receives.
  final double netEarnings;

  /// Percentage change vs. the equivalent previous period
  /// (positive = up, negative = down).
  final double trendPct;

  /// Net earnings not yet transferred to the bank.
  final double pendingPayout;

  /// Net earnings already transferred to the bank in this period.
  final double paidOut;

  /// Friendly date string for the next scheduled transfer,
  /// or "—" when there is nothing pending.
  final String nextPayoutDate;

  final List<EarningsBar> chartBars;
  final List<EarningsTransaction> transactions;
}

// ── Controller ────────────────────────────────────────────────────────────────

class BusinessEarningsController extends GetxController {
  // ── Reactive state ────────────────────────────────────────────────────────

  final selectedPeriod = AnalyticsPeriod.week.obs;
  final isLoading = false.obs;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Exhaustive switch — adding a new [AnalyticsPeriod] value without a case
  /// here produces a compile-time error, making null impossible.
  EarningsData get currentData => switch (selectedPeriod.value) {
    AnalyticsPeriod.today => _today,
    AnalyticsPeriod.week => _week,
    AnalyticsPeriod.month => _month,
    AnalyticsPeriod.lastMonth => _lastMonth,
    AnalyticsPeriod.lastThreeMonths => _lastThreeMonths,
  };

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> selectPeriod(AnalyticsPeriod period) async {
    if (selectedPeriod.value == period) return;
    isLoading.value = true;
    selectedPeriod.value = period;
    await Future.delayed(const Duration(milliseconds: 350));
    isLoading.value = false;
  }

  // ── Shared mock transactions ──────────────────────────────────────────────
  // Shared across all periods — fine for mock data; replace with period-scoped
  // API results when the backend is ready.

  static const _transactions = [
    EarningsTransaction(
      orderId: '#1043',
      customerName: 'Sarah M.',
      offerName: 'Bakery surprise bag',
      gross: 9.95,
      fee: 1.49,
      net: 8.46,
      isPaid: false,
      timeLabel: 'Today, 2:45 PM',
    ),
    EarningsTransaction(
      orderId: '#1042',
      customerName: 'James K.',
      offerName: 'Meal of the day',
      gross: 19.95,
      fee: 2.99,
      net: 16.96,
      isPaid: false,
      timeLabel: 'Today, 1:20 PM',
    ),
    EarningsTransaction(
      orderId: '#1041',
      customerName: 'Aisha R.',
      offerName: 'Veggie pack × 5',
      gross: 49.95,
      fee: 7.49,
      net: 42.46,
      isPaid: true,
      timeLabel: 'Today, 11:05 AM',
    ),
    EarningsTransaction(
      orderId: '#1040',
      customerName: 'Tom B.',
      offerName: 'Dessert box × 2',
      gross: 19.90,
      fee: 2.99,
      net: 16.91,
      isPaid: true,
      timeLabel: 'Yesterday, 6:30 PM',
    ),
    EarningsTransaction(
      orderId: '#1039',
      customerName: 'Emma S.',
      offerName: 'Bakery surprise bag × 3',
      gross: 29.85,
      fee: 4.48,
      net: 25.37,
      isPaid: true,
      timeLabel: 'Yesterday, 5:15 PM',
    ),
  ];

  // ── Mock datasets ─────────────────────────────────────────────────────────
  // Service fee = 15 % of gross. Net = gross − fee + adjustments.

  static const _today = EarningsData(
    grossRevenue: 284.00,
    serviceFee: 42.60,
    serviceFeePct: 0.15,
    adjustments: 0.00,
    netEarnings: 241.40,
    trendPct: 12.3,
    pendingPayout: 241.40,
    paidOut: 0.00,
    nextPayoutDate: 'Tomorrow',
    chartBars: [
      EarningsBar('8am', 15),
      EarningsBar('10am', 46),
      EarningsBar('12pm', 70),
      EarningsBar('2pm', 52),
      EarningsBar('4pm', 32),
      EarningsBar('6pm', 0),
    ],
    transactions: _transactions,
  );

  static const _week = EarningsData(
    grossRevenue: 1284.00,
    serviceFee: 192.60,
    serviceFeePct: 0.15,
    adjustments: -15.00,
    netEarnings: 1076.40,
    trendPct: 8.7,
    pendingPayout: 280.50,
    paidOut: 795.90,
    nextPayoutDate: 'Mon, Jun 30',
    chartBars: [
      EarningsBar('Mon', 121),
      EarningsBar('Tue', 168),
      EarningsBar('Wed', 149),
      EarningsBar('Thu', 199),
      EarningsBar('Fri', 241),
      EarningsBar('Sat', 139),
      EarningsBar('Sun', 74),
    ],
    transactions: _transactions,
  );

  static const _month = EarningsData(
    grossRevenue: 4820.00,
    serviceFee: 723.00,
    serviceFeePct: 0.15,
    adjustments: -45.00,
    netEarnings: 4052.00,
    trendPct: 14.5,
    pendingPayout: 312.20,
    paidOut: 3739.80,
    nextPayoutDate: 'Mon, Jun 30',
    chartBars: [
      EarningsBar('Wk 1', 833),
      EarningsBar('Wk 2', 1054),
      EarningsBar('Wk 3', 1343),
      EarningsBar('Wk 4', 867),
    ],
    transactions: _transactions,
  );

  static const _lastMonth = EarningsData(
    grossRevenue: 4210.00,
    serviceFee: 631.50,
    serviceFeePct: 0.15,
    adjustments: -30.00,
    netEarnings: 3548.50,
    trendPct: -3.2,
    pendingPayout: 0.00,
    paidOut: 3548.50,
    nextPayoutDate: '—',
    chartBars: [
      EarningsBar('Wk 1', 740),
      EarningsBar('Wk 2', 952),
      EarningsBar('Wk 3', 799),
      EarningsBar('Wk 4', 1088),
    ],
    transactions: _transactions,
  );

  static const _lastThreeMonths = EarningsData(
    grossRevenue: 13650.00,
    serviceFee: 2047.50,
    serviceFeePct: 0.15,
    adjustments: -95.00,
    netEarnings: 11507.50,
    trendPct: 9.8,
    pendingPayout: 312.20,
    paidOut: 11195.30,
    nextPayoutDate: 'Mon, Jun 30',
    chartBars: [
      EarningsBar('Month 1', 3579),
      EarningsBar('Month 2', 4097),
      EarningsBar('Month 3', 3923),
    ],
    transactions: _transactions,
  );
}
