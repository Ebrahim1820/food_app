import 'package:get/get.dart';

abstract class BusinessAnalyticsStrings {
  static String get sectionRevenue => 'bizAnalytics_sectionRevenue'.tr;
  static String get sectionTopOffers => 'bizAnalytics_sectionTopOffers'.tr;
  static String get sectionOrdersByStatus =>
      'bizAnalytics_sectionOrdersByStatus'.tr;
  static String get kpiRevenue => 'bizAnalytics_kpiRevenue'.tr;
  static String get kpiOrders => 'bizAnalytics_kpiOrders'.tr;
  static String get kpiAvgOrder => 'bizAnalytics_kpiAvgOrder'.tr;
  static String get kpiCompletion => 'bizAnalytics_kpiCompletion'.tr;

  static String ordersCount(int n) =>
      'bizAnalytics_ordersCount'.trParams({'n': '$n'});
}

abstract class BusinessEarningsStrings {
  static String get sectionNetEarnings => 'bizEarnings_sectionNetEarnings'.tr;
  static String get sectionBreakdown => 'bizEarnings_sectionBreakdown'.tr;
  static String get sectionPayout => 'bizEarnings_sectionPayout'.tr;
  static String get sectionTransactions => 'bizEarnings_sectionTransactions'.tr;
  static String get heroLabel => 'bizEarnings_heroLabel'.tr;
  static String get grossRevenue => 'bizEarnings_grossRevenue'.tr;
  static String get netEarnings => 'bizEarnings_netEarnings'.tr;
  static String get refundsAdjustments => 'bizEarnings_refundsAdjustments'.tr;
  static String get bankAccount => 'bizEarnings_bankAccount'.tr;
  static String get pending => 'bizEarnings_pending'.tr;
  static String get paidOut => 'bizEarnings_paidOut'.tr;
  static String get viewAllTransactions => 'bizEarnings_viewAllTransactions'.tr;
  static String get paidBadge => 'bizEarnings_paidBadge'.tr;
  static String get pendingBadge => 'bizEarnings_pendingBadge'.tr;

  static String serviceFee(String pct) =>
      'bizEarnings_serviceFee'.trParams({'pct': pct});
  static String nextPayoutOn(String date) =>
      'bizEarnings_nextPayoutOn'.trParams({'date': date});
}

abstract class BusinessDashboardStrings {
  static String get metricTodaysRevenue => 'bizDash_metricTodaysRevenue'.tr;
  static String get metricOrdersToday => 'bizDash_metricOrdersToday'.tr;
  static String get metricAvgOrderValue => 'bizDash_metricAvgOrderValue'.tr;
  static String get metricRating => 'bizDash_metricRating'.tr;
  static String get couldNotUpdateStatus => 'bizDash_couldNotUpdateStatus'.tr;
  static String get checkConnection => 'bizDash_checkConnection'.tr;
  static String get greetingMorning => 'bizDash_greetingMorning'.tr;
  static String get greetingAfternoon => 'bizDash_greetingAfternoon'.tr;
  static String get greetingEvening => 'bizDash_greetingEvening'.tr;
  static String get noActiveOrders => 'bizDash_noActiveOrders'.tr;
}
