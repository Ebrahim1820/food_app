import 'package:food_app/utils/currency_formatter.dart';
import 'package:get/get.dart';

abstract class CustomerOrderStrings {
  static String get pageTitle => 'custOrder_pageTitle'.tr;
  static String get searchHint => 'custOrder_searchHint'.tr;
  static String get sortNewest => 'custOrder_sortNewest'.tr;
  static String get sortOldest => 'custOrder_sortOldest'.tr;
  static String get sortPrice => 'custOrder_sortPrice'.tr;
  static String get sortPriceLowHigh => 'custOrder_sortPriceLowHigh'.tr;
  static String get sortPriceHighLow => 'custOrder_sortPriceHighLow'.tr;
  static String get filterStatusDefault => 'custOrder_filterStatusDefault'.tr;
  static String get filterToday => 'custOrder_filterToday'.tr;
  static String get filterThisWeek => 'custOrder_filterThisWeek'.tr;
  static String get sectionActive => 'custOrder_sectionActive'.tr;
  static String get sectionDone => 'custOrder_sectionDone'.tr;
  static String get emptyTitle => 'custOrder_emptyTitle'.tr;
  static String get emptySubtitle => 'custOrder_emptySubtitle'.tr;
  static String get filteredEmptyTitle => 'custOrder_filteredEmptyTitle'.tr;
  static String get filteredEmptySubtitle =>
      'custOrder_filteredEmptySubtitle'.tr;
  static String get clearFiltersButton => 'custOrder_clearFiltersButton'.tr;
  static String get noAddress => 'custOrder_noAddress'.tr;
  static String get tryAgain => 'custOrder_tryAgain'.tr;
  static String get deliveryLabel => 'custOrder_deliveryLabel'.tr;
  static String get itemColumnHeader => 'custOrder_itemColumnHeader'.tr;
  static String get unitColumnHeader => 'custOrder_unitColumnHeader'.tr;
  static String get totalColumnHeader => 'custOrder_totalColumnHeader'.tr;
  static String get deleteDialogTitle => 'custOrder_deleteDialogTitle'.tr;
  static String get deleteDialogCancel => 'custOrder_deleteDialogCancel'.tr;
  static String get deleteDialogConfirm => 'custOrder_deleteDialogConfirm'.tr;
  static String get cancelDialogTitle => 'custOrder_cancelDialogTitle'.tr;
  static String get cancelReasonLabel => 'custOrder_cancelReasonLabel'.tr;
  static String get cancelReasonOptionalBadge =>
      'custOrder_cancelReasonOptionalBadge'.tr;
  static String get cancelReasonOtherHint =>
      'custOrder_cancelReasonOtherHint'.tr;
  static String get keepOrderButton => 'custOrder_keepOrderButton'.tr;
  static String get cancelOrderButton => 'custOrder_cancelOrderButton'.tr;
  static const cancellationReasonOther = 'Other…';

  static String orderNumber(dynamic id) => 'custOrder_orderNumber'.trParams({
    'id': CurrencyFormatter.localizeDigits('$id'),
  });
  static String deleteDialogBody(dynamic id) => 'custOrder_deleteDialogBody'
      .trParams({'id': CurrencyFormatter.localizeDigits('$id')});
  static String cancelDialogSubtitle(dynamic id) =>
      'custOrder_cancelDialogSubtitle'.trParams({
        'id': CurrencyFormatter.localizeDigits('$id'),
      });
  static String itemCount(int n) =>
      (n == 1 ? 'custOrder_itemCountOne' : 'custOrder_itemCountOther').trParams(
        {'n': '$n'},
      );

  // Edit order screen
  static String get editSectionItems => 'custOrder_editSectionItems'.tr;
  static String get editSectionAddress => 'custOrder_editSectionAddress'.tr;
  static String get editSectionNotes => 'custOrder_editSectionNotes'.tr;
  static String get editNoAddresses => 'custOrder_editNoAddresses'.tr;
  static String get editNotesHint => 'custOrder_editNotesHint'.tr;
  static String get editSaveButton => 'custOrder_editSaveButton'.tr;

  // Order detail — payment summary
  static String get paymentSubtotal => 'custOrder_paymentSubtotal'.tr;
  static String get paymentDelivery => 'custOrder_paymentDelivery'.tr;
  static String get paymentTotal => 'custOrder_paymentTotal'.tr;
  static String get paymentMethodLabel => 'custOrder_paymentMethod'.tr;
  static String get paymentStatusLabel => 'custOrder_paymentStatus'.tr;

  // Order detail — delivery section
  static String get deliveryAddress => 'custOrder_deliveryAddress'.tr;
  static String get noDeliveryAddress => 'custOrder_noDeliveryAddress'.tr;
  static String get estimatedDelivery => 'custOrder_estimatedDelivery'.tr;
  static String get estimatedPickup => 'custOrder_estimatedPickup'.tr;

  // Order detail — status tracker
  static String get trackerPlaced => 'custOrder_trackerPlaced'.tr;
  static String get trackerConfirmed => 'custOrder_trackerConfirmed'.tr;
  static String get trackerReady => 'custOrder_trackerReady'.tr;
  static String get trackerCompleted => 'custOrder_trackerCompleted'.tr;
  static String get cancelledBannerTitle => 'custOrder_cancelledBannerTitle'.tr;
  static String get cancellationReasonLabel =>
      'custOrder_cancellationReasonLabel'.tr;

  // Order detail — location section
  static String get locationPickupTitle => 'custOrder_locationPickupTitle'.tr;
  static String get callButton => 'custOrder_callButton'.tr;
  static String get directionsButton => 'custOrder_directionsButton'.tr;

  // Order detail — help section
  static String get helpTitle => 'custOrder_helpTitle'.tr;
  static String get helpSubtitle => 'custOrder_helpSubtitle'.tr;
  static String get contactBusinessButton =>
      'custOrder_contactBusinessButton'.tr;

  // Order detail — actions section
  static String get editOrderButton => 'custOrder_editOrderButton'.tr;
  static String get reorderButton => 'custOrder_reorderButton'.tr;
  static String get contactSupport => 'custOrder_contactSupport'.tr;

  static String editAppBarTitle(dynamic id) =>
      'custOrder_editAppBarTitle'.trParams({'id': '$id'});
  static String editUnitPrice(String price) =>
      'custOrder_editUnitPrice'.trParams({'price': price});

  // Snackbars & error messages (OrderController)
  static String get placedTitle => 'order_placedTitle'.tr;
  static String get placedBody => 'order_placedBody'.tr;
  static String get errorPlaceBody => 'order_errorPlaceBody'.tr;
  static String get updatedTitle => 'order_updatedTitle'.tr;
  static String get updatedBody => 'order_updatedBody'.tr;
  static String get errorUpdateBody => 'order_errorUpdateBody'.tr;
  static String get cancelledTitle => 'order_cancelledTitle'.tr;
  static String get errorCancelBody => 'order_errorCancelBody'.tr;
  static String get errorDeleteBody => 'order_errorDeleteBody'.tr;
  static String get errorIdentifyAccount => 'order_errorIdentifyAccount'.tr;
  static String get errorLoadOrders => 'order_errorLoadOrders'.tr;
  static String get errorLoadDetail => 'order_errorLoadDetail'.tr;
  static String cancelledBody(dynamic id) =>
      'order_cancelledBody'.trParams({'id': '$id'});

  static List<String> get cancellationReasons => [
    'custOrder_cancelReason0'.tr,
    'custOrder_cancelReason1'.tr,
    'custOrder_cancelReason2'.tr,
    'custOrder_cancelReason3'.tr,
    'custOrder_cancelReason4'.tr,
  ];
}
