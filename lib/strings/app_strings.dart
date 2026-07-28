import 'package:get/get.dart';

abstract class AppStrings {
  static String get appName => 'app_name'.tr;
}

abstract class NavigationBarStrings {
  static String get home => 'navBar_home'.tr;
  static String get favorites => 'navBar_favorites'.tr;
  static String get orders => 'navBar_orders'.tr;
  static String get profile => 'navBar_profile'.tr;
  static String get dashboard => 'navBar_dashboard'.tr;
}

abstract class NavBarTitle {
  static String get findFreshFoods => 'navTitle_findFreshFoods'.tr;
  static String get favorites => 'navTitle_favorites'.tr;
  static String get myOrders => 'navTitle_myOrders'.tr;
  static String get profile => 'navTitle_profile'.tr;

  static List<String> get titles => [
    findFreshFoods,
    favorites,
    myOrders,
    profile,
  ];
}

/// The big brand heading + tagline in `ShellAppBar`'s Row 2 (e.g.
/// "PerkaFood" / "Find Fresh Food") — localized so the brand name itself
/// (e.g. "پرکا فود") shows when the app is switched to Farsi.
abstract class MarketBrandStrings {
  static String get dashboardTitle => 'brand_dashboardTitle'.tr;

  /// Neutral, market-less brand title — e.g. for the Dashboard's combined
  /// Orders tab, which spans Food + Cosmetic and so shouldn't wear either
  /// market's own brand title.
  static String get perkaTitle => 'brand_perkaTitle'.tr;
  static String get foodTitle => 'brand_foodTitle'.tr;
  static String get cosmeticsTitle => 'brand_cosmeticsTitle'.tr;
  static String get cosmeticsSubtitle => 'brand_cosmeticsSubtitle'.tr;
}

/// The placeholder body shown on [CosmeticCustomerHomeScreen] for the
/// Favorites/Orders/Profile bottom-nav tabs — Cosmetics has no market-scoped
/// equivalent of those yet (see DashboardController.onTileTap doc), so
/// tapping them used to fall through to the *Food* MainNavigationScreen
/// instead of staying inside the Cosmetics section.
abstract class CosmeticComingSoonStrings {
  static String title(String tab) =>
      'cosmetic_tabComingSoonTitle'.trParams({'tab': tab});
  static String get body => 'cosmetic_tabComingSoonBody'.tr;
}

/// The "Perka Hub" service-switcher bottom sheet, opened from the bottom
/// nav's center floating button.
abstract class HubSheetStrings {
  static String get title => 'hub_title'.tr;
  static String get subtitle => 'hub_subtitle'.tr;
}

abstract class ProfileMenuStrings {
  static String get profile => 'profileMenu_profile'.tr;
  static String get orders => 'profileMenu_orders'.tr;
  static String get settings => 'profileMenu_settings'.tr;
  static String get help => 'profileMenu_help'.tr;
  static String get logout => 'profileMenu_logout'.tr;
}

abstract class PartnerNavBarStrings {
  static String get dashboard => 'partnerNav_dashboard'.tr;
  static String get orders => 'partnerNav_orders'.tr;
  static String get menu => 'partnerNav_menu'.tr;
  static String get earnings => 'partnerNav_earnings'.tr;
}

abstract class PartnerNavBarTitle {
  static String get overview => 'partnerNavTitle_overview'.tr;
  static String get liveOrders => 'partnerNavTitle_liveOrders'.tr;
  static String get menu => 'partnerNavTitle_menu'.tr;
  static String get earnings => 'partnerNavTitle_earnings'.tr;

  static List<String> get titles => [overview, liveOrders, menu, earnings];
}

abstract class PartnerStrings {
  static String get partnerTag => 'partner_partnerTag'.tr;
  static String get open => 'partner_open'.tr;
  static String get closed => 'partner_closed'.tr;
  static String get openSubtitle => 'partner_openSubtitle'.tr;
  static String get closedSubtitle => 'partner_closedSubtitle'.tr;
  static String get quickActions => 'partner_quickActions'.tr;
  static String get addMenuItem => 'partner_addMenuItem'.tr;
  static String get viewOrders => 'partner_viewOrders'.tr;
  static String get earnings => 'partner_earnings'.tr;
  static String get reviews => 'partner_reviews'.tr;
  static String get liveOrders => 'partner_liveOrders'.tr;
  static String get viewAll => 'partner_viewAll'.tr;
  static String get noOrders => 'partner_noOrders'.tr;
  static String get noOrdersHint => 'partner_noOrdersHint'.tr;
  static String get profile => 'partner_profile'.tr;
  static String get settings => 'partner_settings'.tr;
  static String get logout => 'partner_logout'.tr;
}
