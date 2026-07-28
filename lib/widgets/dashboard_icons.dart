import 'package:flutter/material.dart';
import 'package:food_app/theme/market_colors.dart' as market_colors;
import 'package:food_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:food_app/enums/market_enums.dart';

/// Icon shown on a market tile (live or coming-soon), keyed by
/// [DashboardMarket.key] / [DashboardComingSoonEntry.key]. Falls back to a
/// generic storefront icon for any market key the app doesn't recognise yet.
IconData marketIcon(String key) {
  final market = Market.tryFromValue(key);
  switch (market) {
    case Market.food:
      return Icons.restaurant_menu_rounded;
    case Market.cosmetic:
      return Icons.auto_awesome_rounded;
    case Market.clothes:
      return Icons.checkroom_rounded;
    case Market.electronics:
      return Icons.devices_rounded;
    case Market.homeAppliances:
      return Icons.kitchen_rounded;
    case Market.autoEquipment:
      return Icons.directions_car_filled_rounded;
    default:
      return Icons.storefront_rounded;
  }
}

/// Client-side override of a market's display name — GET /dashboard's
/// `label` field is backend-generated English only (no i18n support there),
/// so this substitutes a localized name for every market key the app knows
/// about and falls back to the raw backend [label] for anything new/unknown
/// rather than showing blank text.
String marketLabel(String key, String label) {
  final market = Market.tryFromValue(key);
  switch (market) {
    case Market.food:
      return 'dashboard_marketLabel_food'.tr;
    case Market.cosmetic:
      return 'dashboard_marketLabel_cosmetic'.tr;
    case Market.clothes:
      return 'dashboard_marketLabel_clothes'.tr;
    case Market.electronics:
      return 'dashboard_marketLabel_electronics'.tr;
    case Market.homeAppliances:
      return 'dashboard_marketLabel_homeAppliances'.tr;
    case Market.autoEquipment:
      return 'dashboard_marketLabel_autoEquipment'.tr;
    default:
      return label;
  }
}

/// One-line marketing copy shown under a live market's title on the
/// Dashboard. Client-side only — GET /dashboard doesn't send copy, just
/// key/label/images, so this is where per-market wording lives.
String marketTagline(String key) {
  final market = Market.tryFromValue(key);
  switch (market) {
    case Market.food:
      return 'dashboard_foodTagline'.tr;
    case Market.cosmetic:
      return 'dashboard_cosmeticTagline'.tr;
    default:
      return '';
  }
}

/// Eye-catching discount callout for a live market's hero/secondary tile —
/// a red tag pinned top-left, separate from [marketTagline] so the two don't
/// repeat the same "X% off" claim. Null hides the badge entirely (only Food
/// has a standing discount story today).
String? marketPromoBadge(String key) {
  final market = Market.tryFromValue(key);
  switch (market) {
    case Market.food:
      return 'dashboard_promoBadgeFood'.tr;
    default:
      return null;
  }
}

/// Solid accent colour for a live market's card when it has no photos to
/// show (e.g. Cosmetics has no heroImages yet) — keeps the tile from
/// looking blank instead of trying to fake a photo.
///
/// Delegates to the single [market_colors.marketAccent] source of truth
/// (shared with `DashboardShell` and the market-specific screens), except
/// that an unrecognised key falls back to `gray600` here rather than the
/// brand green — a plain grey reads better for an unbuilt/unknown tile than
/// defaulting it to look like the Food market.
Color marketAccentColor(String key) {
  if (!market_colors.marketColorMap.containsKey(key)) return AppColors.gray600;
  return market_colors.marketAccent(key);
}

/// Local marketing photos for a live market's hero/secondary tile carousel,
/// keyed the same way as [marketIcon]/[marketTagline]. Takes priority over
/// [DashboardMarket.heroImages] (the backend's real business photos) since
/// neither Food nor Cosmetics has that wired up with real photos yet —
/// swap a market's entry out once its backend starts sending real ones.
List<String> marketLocalBannerImages(String key) {
  final market = Market.tryFromValue(key);
  switch (market) {
    case Market.food:
      return const [
        'assets/dashboard/food_banner/food_banner_1.jpeg',
        'assets/dashboard/food_banner/food_banner_2.jpeg',
        'assets/dashboard/food_banner/food_banner_3.jpg',
        'assets/dashboard/food_banner/food_banner_4.jpeg',
        'assets/dashboard/food_banner/food_banner_5.jpg',
      ];
    case Market.cosmetic:
      return const [
        'assets/dashboard/cosmetics_banner/cosmetics_banner_1.jpeg',
        'assets/dashboard/cosmetics_banner/cosmetics_banner_2.jpeg',
        'assets/dashboard/cosmetics_banner/cosmetics_banner_3.jpeg',
      ];
    default:
      return const [];
  }
}
