// lib/src/dashboard/view/app_shell_screen.dart
//
// The single post-login destination — one persistent AppBar/Drawer/BottomNav
// shell for the whole app, replacing what used to be three separate routed
// screens (DashboardScreen, MainNavigationScreen, CosmeticCustomerHomeScreen)
// that each built their own chrome and their own GlobalBottomNav instance.
//
// Only the Home tab (index 0) changes with which market is selected
// (NavigationController.activeMarket): null shows the Dashboard's market
// tiles, 'food'/'cosmetic' show that market's browse screen. Favorites
// (index 1) is a single global list shared by every market — see
// FavoritesOfferController — so it renders identically regardless of
// activeMarket. Orders (index 2) stays per-market (Food/Cosmetic have their
// own order history, merged on the Dashboard's own Orders tab); Profile
// (index 3) is shared across markets already.
import 'package:flutter/material.dart';
import 'package:food_app/constants/api_endpoints.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:food_app/enums/market_enums.dart';
import 'package:food_app/controllers/dashboard_controller.dart';
import 'package:food_app/screens/dashboard/view/dashboard_home_tiles.dart';
import 'package:food_app/widgets/dashboard/widgets/account_drawer.dart';
import 'package:food_app/screens/dashboard/view/dashboard_order_list_screen.dart';
import 'package:food_app/screens/dashboard/view/dashboard_orders_merger.dart';
import 'package:food_app/screens/dashboard/view/dashboard_shell.dart';
import 'package:food_app/screens/dashboard/view/global_bottom_nav.dart';
import 'package:food_app/screens/dashboard/view/shell_leading_avatar_ring.dart';
import 'package:food_app/screens/cosmetic_teil/customer_views/customer_cosmetic_screen.dart';
import 'package:food_app/screens/cosmetic_teil/orders/views/cosmetic_order_list_screen.dart';
import 'package:food_app/strings/product_strings.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_controller.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_order_controller.dart';
import 'package:food_app/controllers/food_controllers/food_customer_controllers/favorites_offer_controller.dart';
import 'package:food_app/controllers/food_controllers/food_customer_controllers/food_offer_controller.dart';
import 'package:food_app/constants/food/customer_constants/customer_offer_strings.dart';
import 'package:food_app/constants/food/customer_constants/customer_favorites_strings.dart';
import 'package:food_app/screens/food_teil/customer_views/customer_food_screen.dart';
import 'package:food_app/screens/food_teil/customer_views/favorites_screen.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/profile_and_orders/orders/controllers/order_controller.dart';
import 'package:food_app/profile_and_orders/orders/views/order_list_screen.dart';
import 'package:food_app/profile_and_orders/profile/views/profile_screen.dart';
import 'package:food_app/screens/auth/keycloak_auth_service.dart';
import 'package:food_app/strings/app_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';
import 'package:food_app/utils/greeting_header.dart';
import 'package:food_app/widgets/common/app_search_field.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/uploadable_avatar.dart';
import 'package:get/get.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  final navController = Get.find<NavigationController>();
  final favoritesController = Get.find<FavoritesOfferController>();
  final orderController = Get.find<OrderController>();
  final authController = Get.find<AuthController>();
  final foodOfferController = Get.find<FoodOfferController>();
  final dashboardController = Get.find<DashboardController>();
  final cosmeticProductController = Get.find<ProductController>(
    tag: Market.cosmetic.value,
  );
  final cosmeticOrderController = Get.find<ProductOrderController>();

  /// Combines Food + Cosmetic orders for the Dashboard's "all markets"
  /// Orders tab (index 2, activeMarket == null) — see its doc comment.
  /// Food's and Cosmetic's own Orders screens don't use this at all.
  late final dashboardOrdersMerger = DashboardOrdersMerger(
    orderController,
    cosmeticOrderController,
  );

  // Owned here, not by the per-tab GetX controllers (fenix:true, can be
  // disposed/recreated independently of this screen) — this widget is what
  // actually stays mounted across every tab switch, and each search field
  // lives in the shell's persistent AppBar slot, not the tab body, so its
  // controller must live exactly as long as this State does.
  final _foodSearchCtrl = TextEditingController();
  final _favoritesSearchCtrl = TextEditingController();
  final _ordersSearchCtrl = TextEditingController();
  final _cosmeticSearchCtrl = TextEditingController();
  final _cosmeticOrdersSearchCtrl = TextEditingController();
  final _dashboardOrdersSearchCtrl = TextEditingController();

  @override
  void dispose() {
    dashboardOrdersMerger.dispose();
    _dashboardOrdersSearchCtrl.dispose();
    _foodSearchCtrl.dispose();
    _favoritesSearchCtrl.dispose();
    _ordersSearchCtrl.dispose();
    _cosmeticSearchCtrl.dispose();
    _cosmeticOrdersSearchCtrl.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    navController.activeMarket.value = null;
    navController.currentIndex.value = 0;
  }

  Widget _homeBody(String? marketKey) {
    final market = Market.tryFromValue(marketKey);

    return switch (market) {
      Market.food => CustomerFoodScreen(),
      Market.cosmetic => CustomerCosmeticScreen(),
      _ =>
        const DashboardHomeTiles(), // Matches Market.clothes, any future Market, or null
    };
  }

  Widget _tabBody(int index, String? market) {
    if (index == 0) return _homeBody(market);
    // Orders stays per-market: Cosmetic has its own order history screen.
    if (market == Market.cosmetic.value && index == 2) {
      return const CosmeticOrderListScreen();
    }
    // Dashboard's Orders tab shows Food + Cosmetic orders combined — see
    // DashboardOrdersMerger's doc comment.
    if (market == null && index == 2) {
      return DashboardOrderListScreen(merger: dashboardOrdersMerger);
    }
    // Favorites (index 1) and Profile (index 3) are shared across every
    // market — same screen regardless of activeMarket.
    return switch (index) {
      1 => FavoritesScreen(searchController: _favoritesSearchCtrl),
      2 => OrderListScreen(searchController: _ordersSearchCtrl),
      _ => ProfileScreen(),
    };
  }

  /// Whether the current tab is showing Food content (which sets its own
  /// background internally and expects the shell's `backgroundColor: null`
  /// theme default) — true for the Food Home tab, and for the shared
  /// Favorites/Profile screens regardless of market (they're the same widget
  /// everywhere now). Orders (index 2) still varies with the active market.
  bool _isFoodContent(int index, String? market) => switch (index) {
    0 => market == Market.food.value,
    1 || 3 => true,
    _ => market != Market.cosmetic.value,
  };

  /// Favorites/Orders/Profile — Cosmetics has no backend for any of these
  /// yet, so show a placeholder rather than leaving this market entirely
  /// (this used to live on the old standalone CosmeticCustomerHomeScreen).
  Widget _cosmeticComingSoonTab(int index) {
    final (icon, label) = switch (index) {
      1 => (Icons.favorite_border, NavigationBarStrings.favorites),
      2 => (Icons.receipt_long_outlined, NavigationBarStrings.orders),
      _ => (Icons.person_outline, NavigationBarStrings.profile),
    };
    return EmptyStateWidget(
      icon: icon,
      title: CosmeticComingSoonStrings.title(label),
      subtitle: CosmeticComingSoonStrings.body,
    );
  }

  /// "24  ·  My Orders" — the count used to live as its own title+badge row
  /// inside OrderListScreen's body; it now lives here instead, in front of
  /// the "My Orders" subtitle already shown in the shell AppBar, so the body
  /// doesn't repeat a title the AppBar already displays.
  String _ordersSubtitle(String? marketKey) {
    final market = Market.tryFromValue(marketKey);

    final count = switch (market) {
      Market.cosmetic => cosmeticOrderController.orders.length,
      Market.food => orderController.totalOrders.value,
      // Dashboard (no market selected) — combined count across both.
      _ =>
        orderController.totalOrders.value +
            cosmeticOrderController.orders.length,
    };
    return '${CurrencyFormatter.localizeDigits('$count')}  ·  ${NavBarTitle.myOrders}';
  }

  (String, String?) _header(int index, String? marketKey) {
    final market = Market.tryFromValue(marketKey);
    if (index != 0) {
      final subtitle = index == 2
          ? _ordersSubtitle(marketKey)
          : NavBarTitle.titles[index];
      // Favorites (index 1) and Profile (index 3) are single screens shared
      // across every market — see FavoritesOfferController and
      // CustomerProfileScreen — so they always wear the neutral Perka brand
      // rather than whichever market happens to be active, same reasoning
      // as the combined Dashboard Orders tab below.
      if (index == 1 || index == 3) {
        return (MarketBrandStrings.perkaTitle, subtitle);
      }
      // Orders on the Dashboard (no market selected) combines Food +
      // Cosmetic — see DashboardOrdersMerger — so it shouldn't wear Food's
      // brand title like the other Dashboard tabs still do.
      if (index == 2 && marketKey == null) {
        return (MarketBrandStrings.perkaTitle, subtitle);
      }
      return marketKey == Market.cosmetic.value
          ? (MarketBrandStrings.cosmeticsTitle, subtitle)
          : (MarketBrandStrings.foodTitle, subtitle);
    }
    return switch (market) {
      Market.food => (MarketBrandStrings.foodTitle, NavBarTitle.titles[0]),
      Market.cosmetic => (
        MarketBrandStrings.cosmeticsTitle,
        MarketBrandStrings.cosmeticsSubtitle,
      ),
      _ => (MarketBrandStrings.dashboardTitle, null),
    };
  }

  /// The shared DashboardShell AppBar search slot's content, per
  /// (tab, market). Read directly (not in a nested Obx) — the caller already
  /// wraps the whole shell in an Obx keyed on currentIndex/activeMarket, so
  /// this rebuilds along with it.
  Widget? _searchBarForIndex(int index, String? marketKey) {
    final market = Market.tryFromValue(marketKey);

    if (index == 0) {
      return switch (market) {
        Market.food => AppSearchField(
          controller: _foodSearchCtrl,
          hint: CustomerHomeStrings.searchHint,
          hasText: foodOfferController.searchText.value.isNotEmpty,
          onChanged: foodOfferController.onSearchChanged,
          onClear: () {
            _foodSearchCtrl.clear();
            foodOfferController.searchText.value = '';
            foodOfferController.onCategorySelected(
              foodOfferController.selectedCategory.value,
            );
            FocusManager.instance.primaryFocus?.unfocus();
          },
        ),
        Market.cosmetic => AppSearchField(
          controller: _cosmeticSearchCtrl,
          hint: ProductStrings.searchHint,
          hasText: cosmeticProductController.searchText.value.isNotEmpty,
          onChanged: cosmeticProductController.onSearchChanged,
          onClear: () {
            _cosmeticSearchCtrl.clear();
            cosmeticProductController.searchText.value = '';
            cosmeticProductController.fetchProducts();
          },
        ),
        _ => AppSearchField(
          controller: dashboardController.searchController,
          hint: 'dashboard_searchHint'.tr,
        ),
      };
    }
    if (market == Market.cosmetic) {
      if (index == 2) {
        return AppSearchField(
          controller: _cosmeticOrdersSearchCtrl,
          hint: ProductStrings.ordersSearchHint,
          hasText: cosmeticOrderController.searchQuery.value.isNotEmpty,
          onChanged: (v) => cosmeticOrderController.searchQuery.value = v,
          onClear: () {
            _cosmeticOrdersSearchCtrl.clear();
            cosmeticOrderController.searchQuery.value = '';
          },
        );
      }
      // Index 1 (Favorites) falls through to the shared block below —
      // Profile (index 3) has no search field yet.
      if (index != 1) return null;
    }
    return switch (index) {
      1 => AppSearchField(
        controller: _favoritesSearchCtrl,
        hint: CustomerFavoritesStrings.searchHint,
        hasText: favoritesController.searchQuery.value.isNotEmpty,
        onChanged: (v) => favoritesController.searchQuery.value = v,
        onClear: () {
          _favoritesSearchCtrl.clear();
          favoritesController.searchQuery.value = '';
        },
      ),
      // Dashboard's combined Orders tab has its own independent search
      // state (DashboardOrdersMerger.searchQuery), not Food's own
      // orderController.searchQuery — see DashboardOrdersMerger's doc
      // comment on why filter state isn't shared across tabs.
      2 =>
        market == null
            ? AppSearchField(
                controller: _dashboardOrdersSearchCtrl,
                hint: CustomerOrderStrings.searchHint,
                hasText: dashboardOrdersMerger.searchQuery.value.isNotEmpty,
                onChanged: (v) => dashboardOrdersMerger.searchQuery.value = v,
                onClear: () {
                  _dashboardOrdersSearchCtrl.clear();
                  dashboardOrdersMerger.searchQuery.value = '';
                },
              )
            : AppSearchField(
                controller: _ordersSearchCtrl,
                hint: CustomerOrderStrings.searchHint,
                hasText: orderController.searchQuery.value.isNotEmpty,
                onChanged: (v) => orderController.searchQuery.value = v,
                onClear: () {
                  _ordersSearchCtrl.clear();
                  orderController.searchQuery.value = '';
                },
              ),
      _ => null, // Profile — nothing to search there.
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = navController.currentIndex.value;
      final market = navController.activeMarket.value;
      final (title, subtitle) = _header(index, market);

      return DashboardShell(
        marketKey: market ?? 'dashboard',
        // Food content sets its own background internally and expects the
        // theme default (null) here; Dashboard tiles and Cosmetics both
        // want the off-white AppColors.background the original screens used,
        // not the theme's pure-white default.
        backgroundColor: _isFoodContent(index, market)
            ? null
            : AppColors.background,
        resizeToAvoidBottomInset: false,
        safeAreaTop: false,
        safeAreaBottom: false,
        appBarElevation: 0,
        showCartButton: true,
        drawer: const AccountDrawer(),
        leadingBuilder: (openDrawer) => ShellLeadingAvatarRing(
          child: UploadableAvatar(
            initials: authController.firstName.isNotEmpty
                ? authController.firstName.characters.first.toUpperCase()
                : '?',
            imageType: 'avatar',
            userIri: authController.userId.isNotEmpty
                ? ApiEndpoints.userIri(authController.userId)
                : null,
            iriResolver: () async {
              final id = Get.find<AuthController>().userId;
              if (id.isNotEmpty) return ApiEndpoints.userIri(id);
              final kcId = await Get.find<KeycloakAuthService>().getUserId();
              return kcId != null && kcId.isNotEmpty
                  ? ApiEndpoints.userIri(kcId)
                  : null;
            },
            size: 32,
            canUpload: false,
            backgroundColor: AppColors.white,
            initialsColor: AppColors.shellBackground,
            onTap: openDrawer,
          ),
        ),
        greeting: GreetingHeader(token: authController.accessToken.value),
        title: title,
        subtitle: subtitle,
        searchBar: _searchBarForIndex(index, market),
        body: _tabBody(index, market),
        bottomNavigationBar: GlobalBottomNav(
          selectedIndex: index,
          activeMarket: market,
          onDestinationSelected: (i) => navController.currentIndex.value = i,
          onDashboardTap: _goToDashboard,
        ),
      );
    });
  }
}
