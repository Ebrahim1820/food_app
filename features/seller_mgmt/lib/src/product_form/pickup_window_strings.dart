import 'package:get/get.dart';

/// Market-agnostic copy for [PickupWindowPicker]/[PickupWindowField] —
/// points at the same translation keys `business_offer_strings.dart`'s
/// `PickupPickerStrings` used, just without pulling in a Food-specific
/// import for a widget that has no Food-specific logic.
abstract class PickupWindowStrings {
  static String get title => 'pickupPicker_title'.tr;
  static String get tabStart => 'pickupPicker_tabStart'.tr;
  static String get tabEnd => 'pickupPicker_tabEnd'.tr;
  static String get notSet => 'pickupPicker_notSet'.tr;
  static String get placeholder => 'pickupPicker_placeholder'.tr;
  static String get confirmReady => 'pickupPicker_confirmReady'.tr;
  static String get confirmPending => 'pickupPicker_confirmPending'.tr;
  static String get timeStart => 'pickupPicker_timeStart'.tr;
  static String get timeEnd => 'pickupPicker_timeEnd'.tr;
}
