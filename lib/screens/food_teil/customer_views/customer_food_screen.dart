// lib/screens/MainNavigationScreen/CustomerFoodScreen/home_screen.dart
//
// Customer home screen for the food market — discovery / category / search
// modes. Thin wiring layer over the generic CustomerDiscoveryScreen<T>
// (see lib/src/shared/customer_business_screens/customer/views/customer_discovery_screen.dart):
// this file owns everything food-specific (categories, FoodOfferController,
// OfferCardCompact) and hands it to the generic screen via a
// CustomerDiscoveryConfig<FoodOfferModel>. Other markets (cosmetic, clothes,
// ...) wire up their own screen the same way against the same generic
// screen, with their own controller/model/card.
//
// Discovery mode (category = "All", no search text):
//   One horizontal row per non-empty category, returned by
//   GET /api/food_offers/sections in a single request.
//
// Category mode (pill tapped, no search text):
//   Same row layout with one row, from GET /api/food_offers/sections/{cat}.
//
// Search mode (user is typing):
//   2-column grid of matching offers from GET /api/food_offers?title=...

import 'package:flutter/material.dart';
import 'package:food_app/constants/food/customer_constants/customer_offer_strings.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_controller.dart';
import 'package:models/models.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:food_app/widgets/common/product_card_compact.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_category.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/customer_discovery_config.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/customer_discovery_screen.dart';
import 'package:get/get.dart';

class CustomerFoodScreen extends StatelessWidget {
  CustomerFoodScreen({super.key});

  //final FoodOfferController controller = Get.find<FoodOfferController>();

  /// Retrieves the market-agnostic [ProductController] registered under the 'cosmetic' tag.
  final ProductController controller = Get.find<ProductController>(
    tag: Market.food.value,
  );
  // Complete category catalogue — covers every key the API can return.
  // The generic screen filters this list down to only what sections
  // actually have, so no pill ever points to an empty category.
  static List<MarketCategory> get _categories => [
    MarketCategory('all', 'cat_all', '✨', Icons.apps_rounded),
    MarketCategory('fast_food', 'cat_fastFood', '🍔', Icons.fastfood_rounded),
    MarketCategory('pizza', 'cat_pizza', '🍕', Icons.local_pizza_rounded),
    MarketCategory(
      'bakery',
      'cat_bakery',
      '🥐',
      Icons.breakfast_dining_rounded,
    ),
    MarketCategory(
      'restaurant',
      'cat_restaurant',
      '🍽',
      Icons.restaurant_rounded,
    ),
    MarketCategory(
      'supermarket',
      'cat_supermarket',
      '🛒',
      Icons.shopping_cart_rounded,
    ),
    MarketCategory('cafe', 'cat_cafe', '☕', Icons.local_cafe_rounded),
    MarketCategory('meals', 'cat_meals', '🍲', Icons.dinner_dining_rounded),
    MarketCategory(
      'groceries',
      'cat_groceries',
      '🛍',
      Icons.shopping_basket_rounded,
    ),
    MarketCategory(
      'bread_pastries',
      'cat_breadPastries',
      '🥖',
      Icons.breakfast_dining_outlined,
    ),
    MarketCategory(
      'fruits_vegetables',
      'cat_fruitsVegetables',
      '🍎',
      Icons.eco_rounded,
    ),
    MarketCategory(
      'hot_drinks',
      'cat_hotDrinks',
      '🍵',
      Icons.emoji_food_beverage_rounded,
    ),
    MarketCategory(
      'cheese_dairy',
      'cat_cheeseDairy',
      '🧀',
      Icons.icecream_rounded,
    ),
    MarketCategory('butcher', 'cat_butcher', '🥩', Icons.set_meal_rounded),
    MarketCategory('fish', 'cat_fish', '🐟', Icons.set_meal_outlined),
    MarketCategory(
      'deli_catering',
      'cat_deliCatering',
      '🥪',
      Icons.lunch_dining_rounded,
    ),
    MarketCategory('flowers', 'cat_flowers', '🌸', Icons.local_florist_rounded),
    MarketCategory('salads', 'cat_salads', '🥗', Icons.eco_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomerDiscoveryScreen<ProductModel>(
      config: CustomerDiscoveryConfig<ProductModel>(
        categories: _categories,
        selectedCategory: controller.selectedCategory,
        availableCategories: controller.availableCategories,
        onCategorySelected: controller.onCategorySelected,
        fallbackCategoryEmoji: CustomerHomeStrings.fallbackCategoryEmoji,

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
        seeAllLabel: CustomerHomeStrings.seeAll,
        emptyIcon: Icons.storefront_outlined,
        emptyTitle: CustomerHomeStrings.noOffersTitle,
        emptySubtitle: CustomerHomeStrings.noOffersSubtitle,
        errorMessage: controller.fetchError,

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
        noResultsTitle: CustomerHomeStrings.noSearchResultsTitle,
        noResultsSubtitle: CustomerHomeStrings.noSearchResultsSubtitle,

        itemBuilder: (product) => ProductCardCompact(offer: product),
      ),
    );
  }
}
