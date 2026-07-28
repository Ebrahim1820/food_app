import 'package:get/get.dart';

abstract class CustomerCheckoutStrings {
  static String get appBarTitle => 'checkout_appBarTitle'.tr;
  static String get deliveryAddressLabel => 'checkout_deliveryAddressLabel'.tr;
  static String get noSavedAddresses => 'checkout_noSavedAddresses'.tr;
  static String get selectAddressHint => 'checkout_selectAddressHint'.tr;
  static String get addNewAddressOption => 'checkout_addNewAddressOption'.tr;
  static String get editAddressLink => 'checkout_editAddressLink'.tr;
  static String get notesLabel => 'checkout_notesLabel'.tr;
  static String get notesHint => 'checkout_notesHint'.tr;
  static String get subtotalLabel => 'checkout_subtotalLabel'.tr;
  static String get deliveryFeeLabel => 'checkout_deliveryFeeLabel'.tr;
  static String get totalLabel => 'checkout_totalLabel'.tr;
  static String get accountErrorTitle => 'checkout_accountErrorTitle'.tr;
  static String get accountErrorBody => 'checkout_accountErrorBody'.tr;
  static String get pickupLabel => 'checkout_pickupLabel'.tr;
  static String get deliverInsteadLabel => 'checkout_deliverInsteadLabel'.tr;
  static String get deliverInsteadOnSubtitle =>
      'checkout_deliverInsteadOnSubtitle'.tr;
  static String get deliverInsteadOffSubtitle =>
      'checkout_deliverInsteadOffSubtitle'.tr;
  static String get noAddressTitle => 'checkout_noAddressTitle'.tr;
  static String get noAddressBody => 'checkout_noAddressBody'.tr;
  static String get addAddressButton => 'checkout_addAddressButton'.tr;

  static String availableQuantity(int qty) =>
      'checkout_availableQuantity'.trParams({'qty': '$qty'});
  static String quantityExceedsAvailable(int qty) =>
      'checkout_quantityExceedsAvailable'.trParams({'qty': '$qty'});
  static String placeOrderButton(String total) =>
      'checkout_placeOrderButton'.trParams({'total': total});
}
