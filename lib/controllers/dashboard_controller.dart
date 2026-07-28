// lib/features/dashboard/dashboard_controller.dart
//
// Drives the post-login Dashboard screen: the market tiles the user picks
// between, and the role-aware "where does this tile tap go" logic.
//
// Lifecycle: registered once via InitialBinding (fenix: true), fetched on
// first Get.find() — i.e. the first time AuthGate/login routes here.

import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:food_app/enums/market_enums.dart';
import 'package:food_app/widgets/dashboard_icons.dart';
import 'package:food_app/models/dashboard_model.dart';
import 'package:food_app/models/user_model.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/services/dashboard_service.dart';
import 'package:food_app/services/data_cache_service.dart';
import 'package:food_app/services/user_service.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  DashboardController(this._dashboardService, this._userService);

  final DashboardService _dashboardService;
  final UserService _userService;

  static const _dashboardCacheKey = 'dashboard_data';

  // ── State ─────────────────────────────────────────────────────────────────

  final Rx<DashboardModel?> dashboard = Rx(null);

  /// The current user's profile, fetched fresh (never cached) so
  /// [businessCapabilities] — which drives tile-tap navigation — is never
  /// stale. Null while loading or if the fetch failed; tile taps fall back
  /// to customer navigation in that case (the safe default).
  final Rx<UserModel?> me = Rx(null);

  final isLoading = false.obs;
  final RxnString fetchError = RxnString();
  final isFromCache = false.obs;

  /// Global search field shown in the Dashboard's AppBar search slot. Owned
  /// here (not locally in DashboardScreen's build method, which previously
  /// created — and never disposed — a new TextEditingController on every
  /// rebuild) — same pattern as FoodOfferController.searchController.
  /// Not yet wired to a backend query: there is no cross-market search
  /// endpoint today, only per-market ones (e.g. FoodOfferController's own
  /// title filter). Present for layout consistency with every other screen;
  /// wiring it up is a follow-up once a global search endpoint exists.
  final searchController = TextEditingController();

  String get firstName => Get.find<AuthController>().firstName;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Cache-first load, same shape as [BusinessPartnerController.fetchMyPartner].
  ///   1. Show cached market tiles immediately if present.
  ///   2. Fetch fresh dashboard data + profile in the background.
  ///   3. On success: update, cache the dashboard, clear isFromCache.
  ///   4. On dashboard-fetch error + cache exists: keep showing cached tiles.
  ///   5. On dashboard-fetch error + no cache: show the error/retry state.
  Future<void> load() async {
    final cached = DataCacheService.load(
      _dashboardCacheKey,
      (json) => DashboardModel.fromJson(json as Map<String, dynamic>),
    );
    if (cached != null && dashboard.value == null) {
      dashboard.value = cached;
      isFromCache.value = true;
    }

    isLoading.value = dashboard.value == null;
    fetchError.value = null;

    try {
      final fresh = await _dashboardService.fetchDashboard();
      dashboard.value = fresh;
      isFromCache.value = false;
      await DataCacheService.save(_dashboardCacheKey, fresh.toJson());
    } catch (_) {
      if (dashboard.value == null) {
        fetchError.value = 'dashboard_loadError'.tr;
      }
      // else: keep showing the cached tiles (isFromCache stays true).
    } finally {
      isLoading.value = false;
    }

    // Best-effort — a failure here just means tile taps fall back to
    // customer navigation, never blocks the Dashboard from rendering.
    try {
      me.value = await _userService.fetchMe();
    } catch (_) {
      // ignore
    }
  }

  DashboardMarket? _findMarket(String key) {
    for (final m in dashboard.value?.markets ?? const <DashboardMarket>[]) {
      if (m.key == key) return m;
    }
    return null;
  }

  /// Implements the spec's tap logic:
  ///   disabled / unknown market → "coming soon" sheet, no navigation
  ///   enabled, capability owner/staff → that market's Business Dashboard
  ///   enabled, otherwise → that market's customer home
  void onTileTap(String marketKey) {
    final market = _findMarket(marketKey);
    if (market == null || !market.enabled) {
      showComingSoonSheet(marketLabel(marketKey, market?.label ?? marketKey));
      return;
    }

    final capability = me.value?.businessCapabilities[marketKey];
    final navController = Get.find<NavigationController>();
    // A business owner/staff who's explicitly switched to "customer view"
    // (see AccountDrawer's role-badge tap) browses like any other
    // customer — including buying from *other* stores in their own
    // market — instead of always bouncing back to their own dashboard.
    final hasBusinessAccess =
        !navController.actingAsCustomer.value &&
        (capability == 'owner' || capability == 'staff');

    if (marketKey == Market.food.value) {
      if (hasBusinessAccess) {
        Get.toNamed(AppRoutes.businessDashboard);
      } else {
        // AppShellScreen is already the on-screen route (this is only ever
        // called from its own Home-tab tiles or its Hub sheet) — switch the
        // shell's Home content in place rather than navigating anywhere.
        navController.activeMarket.value = 'food';
        navController.currentIndex.value = 0;
      }
    } else if (marketKey == Market.cosmetic.value) {
      // Cosmetic now has a real (if minimal) business side — see
      // MyProductsScreen — backed by the generic Product/ProductOrder
      // pipeline, mirroring the 'food' branch above.
      if (hasBusinessAccess) {
        Get.toNamed(AppRoutes.cosmeticBusinessProducts);
      } else {
        navController.activeMarket.value = Market.cosmetic.value;
        navController.currentIndex.value = 0;
      }
    } else {
      // An enabled market with no screen built for it yet — treat as coming
      // soon rather than navigating nowhere.
      showComingSoonSheet(marketLabel(market.key, market.label));
    }
  }

  void showComingSoonSheet(String marketLabel) {
    Get.bottomSheet(_ComingSoonSheet(marketLabel: marketLabel));
  }
}

class _ComingSoonSheet extends StatelessWidget {
  const _ComingSoonSheet({required this.marketLabel});

  final String marketLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.gray500,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'dashboard_marketComingSoon'.trParams({'market': marketLabel}),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'dashboard_comingSoonBody'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            CustomDynamicButton(
              label: 'dashboard_gotIt'.tr,
              onPressed: () => Get.back(),
              fullWidth: true,
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
