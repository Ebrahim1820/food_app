// lib/src/markets/cosmetic/customer/views/customer_cosmetic_screen.dart

import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/customer_discovery_config.dart';
import 'package:food_app/widgets/common/product_card_compact.dart';
import 'package:get/get.dart';

import 'package:food_app/constants/cosmetic/cosmetic_strings.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_controller.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_category.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/customer_discovery_screen.dart';
import 'package:i18n/i18n.dart';

/// Customer discovery screen for the Cosmetic market — discovery / category / search modes.
///
/// Thin wiring layer over the generic [CustomerDiscoveryScreen<ProductModel>]
/// (see `lib/src/shared/customer_business_screens/customer/views/customer_discovery_screen.dart`):
/// this file owns everything cosmetic-specific (categories, cosmetic [ProductController])
/// and hands it to the generic screen via a [CustomerDiscoveryConfig<ProductModel>].
///
/// **Discovery Mode** (category = "All", no search text):
///   One horizontal row per non-empty category, returned by
///   `GET /api/products/sections/cosmetic` in a single request.
///
/// **Category Mode** (pill tapped, no search text):
///   Same row layout with one row, from `GET /api/products/sections/cosmetic/{cat}`.
///
/// **Search Mode** (user is typing):
///   2-column grid of matching products from `GET /api/products?market=cosmetic&title=...`.
class CustomerCosmeticScreen extends StatelessWidget {
  CustomerCosmeticScreen({super.key});

  /// Retrieves the market-agnostic [ProductController] registered under the 'cosmetic' tag.
  final ProductController controller = Get.find<ProductController>(
    tag: Market.cosmetic.value,
  );

  /// Complete category catalogue for cosmetics.
  ///
  /// The generic screen automatically filters this list down to categories that actually contain items,
  /// ensuring category pills never point to empty sections.
  static const List<MarketCategory> _categories = [
    MarketCategory('all', 'cosmetic_categoryAll', '✨', Icons.apps_rounded),
    MarketCategory(
      'skincare',
      'cosmetic_categorySkincare',
      '🧴',
      Icons.face_retouching_natural_rounded,
    ),
    MarketCategory(
      'makeup',
      'cosmetic_categoryMakeup',
      '💄',
      Icons.brush_rounded,
    ),
    MarketCategory(
      'haircare',
      'cosmetic_categoryHaircare',
      '💇',
      Icons.content_cut_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomerDiscoveryScreen<ProductModel>(
      config: CustomerDiscoveryConfig<ProductModel>(
        // ── Category Pills Setup ─────────────────────────────────────────────
        categories: _categories,
        selectedCategory: controller.selectedCategory,
        availableCategories: controller.availableCategories,
        onCategorySelected: controller.onCategorySelected,
        fallbackCategoryEmoji: '💄',

        // ── Discovery / Sections State & Handlers ───────────────────────────
        isFromCache: controller.isFromCache,
        onRefreshStale: () => controller.fetchSections(),
        onPullToRefresh: () async {
          if (controller.selectedCategory.value == 'all') {
            await controller.fetchSections();
          } else {
            await controller.fetchCategorySection(
              controller.selectedCategory.value,
            );
          }
        },
        sectionsLoading: controller.sectionsLoading,
        sections: controller.sections,
        loadingMoreSections: controller.loadingMoreSections,
        onLoadMoreSection: controller.loadSectionPage,
        seeAllLabel: ProductStrings.seeAll,
        emptyIcon: Icons.auto_awesome_outlined,
        emptyTitle: CosmeticStrings.browseEmptyTitle,
        emptySubtitle: CosmeticStrings.browseEmptySubtitle,
        errorMessage: controller.fetchError,

        // ── Search & Flat Discovery State & Handlers ────────────────────────
        searchText: controller.searchText,
        searchLoading: controller.loading,
        searchLoadingMore: controller.loadingMore,
        searchResults: controller.filteredProducts,
        searchScrollController: controller.scrollController,
        onSearchRefresh: () async {
          controller.resetPagination();
          await controller.fetchProducts();
        },
        noResultsIcon: Icons.search_off_rounded,
        noResultsTitle: CosmeticStrings.browseNoMatchesTitle,
        noResultsSubtitle: CosmeticStrings.browseNoMatchesSubtitle,

        // ── Visual Layout & Item Builder ─────────────────────────────────────
        itemCardWidth: 170,
        itemCardHeight: 240,
        itemBuilder: (product) => ProductCardCompact(offer: product),
      ),
    );
  }
}
