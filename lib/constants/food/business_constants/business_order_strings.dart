import 'package:get/get.dart';

abstract class OrderStatusLabels {
  static String get newOrder => 'orderStatus_new'.tr;
  static String get confirmed => 'orderStatus_confirmed'.tr;
  static String get preparing => 'orderStatus_preparing'.tr;
  static String get ready => 'orderStatus_ready'.tr;
  static String get delivered => 'orderStatus_delivered'.tr;
  static String get cancelled => 'orderStatus_cancelled'.tr;
  static String get guest => 'orderStatus_guest'.tr;
}

abstract class BusinessOrdersScreenStrings {
  static String get appBarTitle => 'bizOrders_appBarTitle'.tr;
  static String get tabNew => 'bizOrders_tabNew'.tr;
  static String get tabActive => 'bizOrders_tabActive'.tr;
  static String get tabDone => 'bizOrders_tabDone'.tr;
  static String get searchHint => 'bizOrders_searchHint'.tr;
  static String get filterOldestFirst => 'bizOrders_filterOldestFirst'.tr;
  static String get filterToday => 'bizOrders_filterToday'.tr;
  static String get filterThisWeek => 'bizOrders_filterThisWeek'.tr;
  static String get errorCouldNotLoad => 'bizOrders_errorCouldNotLoad'.tr;
  static String get retryButton => 'bizOrders_retryButton'.tr;
  static String get cancelDialogTitle => 'bizOrders_cancelDialogTitle'.tr;
  static String get cancelDialogConfirm => 'bizOrders_cancelDialogConfirm'.tr;
  static String get cancelDialogKeep => 'bizOrders_cancelDialogKeep'.tr;

  static String cancelDialogBody(String orderId) =>
      'bizOrders_cancelDialogBody'.trParams({'orderId': orderId});

  static String get doneLimitShow => 'bizOrders_doneLimitShow'.tr;
  static String get doneLimitAll => 'bizOrders_doneLimitAll'.tr;
  static String doneLimitLast(int n) =>
      'bizOrders_doneLimitLast'.trParams({'n': '$n'});

  static String get doneStatusShow => 'bizOrders_doneStatusShow'.tr;
}

abstract class BusinessOrderDetailStrings {
  static String get sectionCustomer => 'bizOrderDetail_sectionCustomer'.tr;
  static String get sectionCustomerNotes =>
      'bizOrderDetail_sectionCustomerNotes'.tr;
  static String get sectionDelivery => 'bizOrderDetail_sectionDelivery'.tr;
  static String get sectionPickup => 'bizOrderDetail_sectionPickup'.tr;
  static String get sectionPriceSummary =>
      'bizOrderDetail_sectionPriceSummary'.tr;
  static String get itemColumnItem => 'bizOrderDetail_itemColumnItem'.tr;
  static String get itemColumnUnit => 'bizOrderDetail_itemColumnUnit'.tr;
  static String get itemColumnTotal => 'bizOrderDetail_itemColumnTotal'.tr;
  static String get itemsLoading => 'bizOrderDetail_itemsLoading'.tr;
  static String get typeDelivery => 'bizOrderDetail_typeDelivery'.tr;
  static String get typePickup => 'bizOrderDetail_typePickup'.tr;
  static String get estDelivery => 'bizOrderDetail_estDelivery'.tr;
  static String get readyBy => 'bizOrderDetail_readyBy'.tr;
  static String get noDeliveryInfo => 'bizOrderDetail_noDeliveryInfo'.tr;
  static String get subtotalLabel => 'bizOrderDetail_subtotalLabel'.tr;
  static String get deliveryFeeLabel => 'bizOrderDetail_deliveryFeeLabel'.tr;
  static String get deliveryFeeFree => 'bizOrderDetail_deliveryFeeFree'.tr;
  static String get totalLabel => 'bizOrderDetail_totalLabel'.tr;
  static String get acceptButton => 'bizOrderDetail_acceptButton'.tr;
  static String get rejectButton => 'bizOrderDetail_rejectButton'.tr;
  static String get cancelButton => 'bizOrderDetail_cancelButton'.tr;
  static String get advanceStartPreparing =>
      'bizOrderDetail_advanceStartPreparing'.tr;
  static String get advanceMarkReady => 'bizOrderDetail_advanceMarkReady'.tr;
  static String get advanceOutForDelivery =>
      'bizOrderDetail_advanceOutForDelivery'.tr;
  static String get advanceMarkComplete =>
      'bizOrderDetail_advanceMarkComplete'.tr;
  static String get advanceFallback => 'bizOrderDetail_advanceFallback'.tr;

  static String appBarTitle(String orderId) =>
      'bizOrderDetail_appBarTitle'.trParams({'orderId': orderId});
}

abstract class BusinessOrderCardStrings {
  static String get acceptButton => 'bizCard_acceptButton'.tr;
  static String get rejectButton => 'bizCard_rejectButton'.tr;
  static String get advanceStartPreparing => 'bizCard_advanceStartPreparing'.tr;
  static String get advanceMarkReady => 'bizCard_advanceMarkReady'.tr;
  static String get advanceOutForDelivery => 'bizCard_advanceOutForDelivery'.tr;
  static String get advanceComplete => 'bizCard_advanceComplete'.tr;
  static String get advanceFallback => 'bizCard_advanceFallback'.tr;
  static String get moreActionsTooltip => 'bizCard_moreActionsTooltip'.tr;
  static String get moveBackAction => 'bizCard_moveBackAction'.tr;
  static String get cancelOrderAction => 'bizCard_cancelOrderAction'.tr;
  static String get doneDelivered => 'bizCard_doneDelivered'.tr;
  static String get doneCancelled => 'bizCard_doneCancelled'.tr;
  static String get detailsButton => 'bizCard_detailsButton'.tr;
  static String get typeDelivery => 'bizCard_typeDelivery'.tr;
  static String get typePickup => 'bizCard_typePickup'.tr;

  static String overflowHint(int count) =>
      'bizCard_overflowHint'.trParams({'count': '$count'});
}

abstract class BusinessEmptyOrdersStrings {
  static String get incomingTitle => 'bizEmpty_incomingTitle'.tr;
  static String get incomingSubtitle => 'bizEmpty_incomingSubtitle'.tr;
  static String get activeTitle => 'bizEmpty_activeTitle'.tr;
  static String get activeSubtitle => 'bizEmpty_activeSubtitle'.tr;
  static String get doneTitle => 'bizEmpty_doneTitle'.tr;
  static String get doneSubtitle => 'bizEmpty_doneSubtitle'.tr;
  static String get listeningChip => 'bizEmpty_listeningChip'.tr;
}
