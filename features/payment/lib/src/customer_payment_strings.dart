import 'package:get/get.dart';

abstract class CustomerPaymentStrings {
  static String get appBarTitle => 'payment_appBarTitle'.tr;
  static String get orderSummaryTitle => 'payment_orderSummaryTitle'.tr;
  static String get subtotalLabel => 'payment_subtotalLabel'.tr;
  static String get deliveryLabel => 'payment_deliveryLabel'.tr;
  static String get totalLabel => 'payment_totalLabel'.tr;
  static String get paymentMethodTitle => 'payment_paymentMethodTitle'.tr;
  static String get gatewayComingSoon => 'payment_gatewayComingSoon'.tr;
  static String get proceedToPaymentButton =>
      'payment_proceedToPaymentButton'.tr;
  static String get securityLine => 'payment_securityLine'.tr;
  static String get selectPaymentMethodError =>
      'payment_selectPaymentMethodError'.tr;
  static String get processingLabel => 'payment_processingLabel'.tr;

  static String get reservedInfo => 'payment_reservedInfo'.tr;
  static String get noAddressError => 'payment_noAddressError'.tr;
  static String get accountVerifyError => 'payment_accountVerifyError'.tr;
  static String get partnerNotFoundError => 'payment_partnerNotFoundError'.tr;
  static String get payOnlineLabel => 'payment_payOnlineLabel'.tr;
  static String get payOnlineSublabel => 'payment_payOnlineSublabel'.tr;
  static String get payAtPickupLabel => 'payment_payAtPickupLabel'.tr;
  static String get payAtPickupSublabel => 'payment_payAtPickupSublabel'.tr;
  static String get cashNoCardHint => 'payment_cashNoCardHint'.tr;
  static String get cashExactAmountHint => 'payment_cashExactAmountHint'.tr;
  static String get confirmAtPickup => 'payment_confirmAtPickup'.tr;

  static String quantityLabel(int qty) =>
      'payment_quantityLabel'.trParams({'qty': '$qty'});
  static String payButton(String amount) =>
      'payment_payButton'.trParams({'amount': amount});

  /// Translates an API paymentStatus value to a display label.
  static String paymentStatusLabel(String status) =>
      switch (status.toLowerCase()) {
        'paid' => 'payment_statusPaid'.tr,
        'refunded' => 'payment_statusRefunded'.tr,
        _ => 'payment_statusPending'.tr,
      };
}
