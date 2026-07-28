import 'package:get/get.dart';

/// Valid category values for the Cosmetics market — mirrors the backend's
/// `CosmeticCategory` enum (`skincare` | `makeup` | `haircare`). A plain
/// string list, not a Dart enum, matching how `BusinessOfferController`
/// already lists Food's categories.
const cosmeticCategories = <String>['skincare', 'makeup', 'haircare'];

/// Whether [category] (e.g. an order item's `categorySnapshot`) belongs to
/// the Cosmetics market. Used to tell a Food order apart from a Cosmetic
/// one client-side — see `OrderController.filteredOrders` and
/// `ProductOrderController.filteredOrders`, which both need this because
/// the shared `/orders` endpoint returns every market's orders together and
/// the embedded `businessPartner.markets` field isn't reliably present on
/// that list response (unlike `categorySnapshot`, which is denormalized
/// onto the order item at creation time and always present).
bool isCosmeticCategory(String category) =>
    cosmeticCategories.contains(category.toLowerCase());

/// Cosmetic-specific translation-key accessors — screen titles, category
/// display names, checkout copy. Generic Product-feature strings live in
/// `product_strings.dart` instead; this file only holds what's genuinely
/// specific to the Cosmetics market.
abstract class CosmeticStrings {
  static String get browseEmptyTitle => 'cosmetic_browseEmptyTitle'.tr;
  static String get browseEmptySubtitle => 'cosmetic_browseEmptySubtitle'.tr;
  static String get browseNoMatchesTitle => 'cosmetic_browseNoMatchesTitle'.tr;
  static String get browseNoMatchesSubtitle =>
      'cosmetic_browseNoMatchesSubtitle'.tr;

  static String get categoryAll => 'cosmetic_categoryAll'.tr;
  static String get categorySkincare => 'cosmetic_categorySkincare'.tr;
  static String get categoryMakeup => 'cosmetic_categoryMakeup'.tr;
  static String get categoryHaircare => 'cosmetic_categoryHaircare'.tr;

  static String categoryLabel(String category) => switch (category) {
    'skincare' => categorySkincare,
    'makeup' => categoryMakeup,
    'haircare' => categoryHaircare,
    _ => category,
  };

  static String get checkoutAppBarTitle => 'cosmeticCheckout_appBarTitle'.tr;
  static String get checkoutQuantityLabel =>
      'cosmeticCheckout_quantityLabel'.tr;
  static String get checkoutNotesLabel => 'cosmeticCheckout_notesLabel'.tr;
  static String get checkoutNotesHint => 'cosmeticCheckout_notesHint'.tr;
  static String get checkoutSuccessTitle =>
      'cosmeticCheckout_successTitle'.tr;
  static String get checkoutSuccessBody => 'cosmeticCheckout_successBody'.tr;
  static String get checkoutErrorTitle => 'cosmeticCheckout_errorTitle'.tr;
  static String get checkoutNotEnoughStock =>
      'cosmeticCheckout_notEnoughStock'.tr;

  static String get ordersTitle => 'cosmeticOrders_title'.tr;
  static String get ordersEmptyTitle => 'cosmeticOrders_emptyTitle'.tr;
  static String get ordersEmptySubtitle => 'cosmeticOrders_emptySubtitle'.tr;
  static String get ordersErrorTitle => 'cosmeticOrders_errorTitle'.tr;
  static String orderNumber(String id) =>
      'cosmeticOrders_orderNumber'.trParams({'id': id});
  static String orderItemCount(int count) =>
      'cosmeticOrders_itemCount'.trParams({'count': '$count'});
  static String get orderCancelButton => 'cosmeticOrders_cancelButton'.tr;
  static String get orderCancelledSnack =>
      'cosmeticOrders_orderCancelledSnack'.tr;

  static String get businessOrdersTitle => 'cosmeticBizOrders_title'.tr;
  static String get businessOrdersEmptyTitle =>
      'cosmeticBizOrders_emptyTitle'.tr;
  static String get businessOrdersEmptySubtitle =>
      'cosmeticBizOrders_emptySubtitle'.tr;
  static String get businessOrderConfirmButton =>
      'cosmeticBizOrders_confirmButton'.tr;
  static String get businessOrderReadyButton =>
      'cosmeticBizOrders_readyButton'.tr;
  static String get businessOrderCompleteButton =>
      'cosmeticBizOrders_completeButton'.tr;
  static String get businessOrderStatusUpdated =>
      'cosmeticBizOrders_statusUpdated'.tr;
  static String get businessOrderUpdateError =>
      'cosmeticBizOrders_updateError'.tr;
}
