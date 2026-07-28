import 'package:get/get.dart';

abstract class CartStrings {
  static String get title => 'cart_title'.tr;
  static String get emptyTitle => 'cart_emptyTitle'.tr;
  static String get emptySubtitle => 'cart_emptySubtitle'.tr;
  static String get browseButton => 'cart_browseButton'.tr;
  static String get clearButton => 'cart_clearButton'.tr;
  static String get clearConfirmTitle => 'cart_clearConfirmTitle'.tr;
  static String get clearConfirmBody => 'cart_clearConfirmBody'.tr;
  static String get clearConfirmConfirm => 'cart_clearConfirmConfirm'.tr;
  static String get clearConfirmCancel => 'cart_clearConfirmCancel'.tr;
  static String get subtotalLabel => 'cart_subtotalLabel'.tr;
  static String get proceedButton => 'cart_proceedButton'.tr;
  static String get addedTitle => 'cart_addedTitle'.tr;
  static String get addedBody => 'cart_addedBody'.tr;
  static String get viewCartAction => 'cart_viewCartAction'.tr;
  static String availableLeft(String qty) =>
      'cart_availableLeft'.trParams({'qty': qty});
  static String get invalidQuantityWarning =>
      'cart_invalidQuantityWarning'.tr;

  static String get switchBusinessTitle => 'cart_switchBusinessTitle'.tr;
  static String get switchBusinessBody => 'cart_switchBusinessBody'.tr;
  static String get switchBusinessConfirm => 'cart_switchBusinessConfirm'.tr;
  static String get switchBusinessCancel => 'cart_switchBusinessCancel'.tr;

  static String get checkoutAppBarTitle => 'cart_checkoutAppBarTitle'.tr;

  static String get updatedTitle => 'cart_updatedTitle'.tr;
  static String removedLine(String titles) =>
      'cart_removedLine'.trParams({'titles': titles});
  static String adjustedLine(String titles) =>
      'cart_adjustedLine'.trParams({'titles': titles});
  static String get okButton => 'cart_okButton'.tr;
}
