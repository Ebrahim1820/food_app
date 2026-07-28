import 'package:get/get.dart';

abstract class BusinessOrderHistoryStrings {
  static String get title => 'orderHistory_title'.tr;
  static String get searchHint => 'orderHistory_searchHint'.tr;
  static String get summaryEyebrow => 'orderHistory_summaryEyebrow'.tr;
  static String get summaryOrders => 'orderHistory_summaryOrders'.tr;
  static String get summaryRevenue => 'orderHistory_summaryRevenue'.tr;
  static String get summaryCompleted => 'orderHistory_summaryCompleted'.tr;
  static String get summaryCancelled => 'orderHistory_summaryCancelled'.tr;
  static String get loadMore => 'orderHistory_loadMore'.tr;
  static String get emptyTitle => 'orderHistory_emptyTitle'.tr;
  static String get emptySubtitle => 'orderHistory_emptySubtitle'.tr;
  static String get errorTitle => 'orderHistory_errorTitle'.tr;
  static String get retry => 'orderHistory_retry'.tr;
  static String get selectCustomDate => 'orderHistory_selectCustomDate'.tr;

  static String get doneTabLiveLabel => 'bizOrders_doneTabLiveLabel'.tr;
  static String get doneTabSubtitle => 'bizOrders_doneTabSubtitle'.tr;
  static String get historyButton => 'bizOrders_historyButton'.tr;

  static String showingOf(int loaded, int total) => 'orderHistory_showingOf'
      .trParams({'loaded': '$loaded', 'total': '$total'});
}
