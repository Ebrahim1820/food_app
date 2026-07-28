// The single global favorites screen, used identically regardless of which
// market (Food, Cosmetic, or the Dashboard) the user is currently browsing —
// see FavoritesOfferController, which already backs a single shared
// `/favorites` list across every market. Thin wiring layer over the generic
// FavoritesScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/favorites_screen.dart).
// This file owns FavoritesOfferController, the full-info OfferCard row
// widget, and the "browse offers" navigation. Lives under food_teil for
// historical reasons but is not Food-specific.
import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:models/models.dart';
import '../../discovery/views/favorites_screen.dart'
    as shared;
import 'package:get/get.dart';

/// Category keys owned by Cosmetic — checked first so its products don't get
/// mislabeled by [FoodCategories.label] (which falls back to "All" for any
/// key it doesn't recognize) now that this list mixes items from every market.
const _cosmeticCategoryKeys = {'skincare', 'makeup', 'haircare'};

String _favoriteCategoryLabel(String cat) =>
    _cosmeticCategoryKeys.contains(cat.toLowerCase())
    ? CosmeticStrings.categoryLabel(cat)
    : FoodCategories.label(cat);

/// Customer favorites screen: search, sort/category filters, and a filtered
/// list of the offers/products the user has saved as favorites, across every
/// market at once.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.searchController,
    required this.onBrowse,
  });

  /// Owned by AppShellScreen (its AppBar renders the actual search field) —
  /// passed down only so the "Clear filters" button here can call .clear()
  /// on it too.
  final TextEditingController searchController;

  /// Called when the user taps "Browse offers" from the empty state — the
  /// app wires this to switching the shell's bottom-nav tab back to Home
  /// (see AppShellScreen), since this package owns no navigation/shell state.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final favCtrl = Get.find<FavoritesOfferController>();

    return shared.FavoritesScreen<ProductModel>(
      config: shared.FavoritesConfig<ProductModel>(
        rawItems: favCtrl.favoriteOffers,
        filterAndSort: favCtrl.filteredFavorites,
        searchQuery: favCtrl.searchQuery,
        sortOrder: favCtrl.sortOrder,
        categoryFilter: favCtrl.categoryFilter,
        availableCategories: (items) =>
            shared.uniqueCategories(items, (o) => o.category),
        categoryLabel: _favoriteCategoryLabel,
        isFromCache: favCtrl.isFromCache,
        onRefreshStale: favCtrl.loadFavorites,
        itemBuilder: (offer) => ProductCard(offer: offer),

        emptyTitle: CustomerFavoritesStrings.emptyTitle,
        emptySubtitle: CustomerFavoritesStrings.emptySubtitle,
        browseButtonLabel: CustomerFavoritesStrings.browseOffersButton,
        onBrowse: onBrowse,

        filteredEmptyTitle: CustomerFavoritesStrings.filteredEmptyTitle,
        filteredEmptySubtitle: CustomerFavoritesStrings.filteredEmptySubtitle,
        clearFiltersButtonLabel: CustomerFavoritesStrings.clearFiltersButton,
        onClearFilters: () {
          searchController.clear();
          favCtrl.searchQuery.value = '';
          favCtrl.categoryFilter.value = 'all';
          favCtrl.sortOrder.value = FavoritesSort.alphabetical;
        },

        categoryAllLabel: FoodCategories.all,
        sortAlphabeticalLabel: CustomerFavoritesStrings.sortAlphabetical,
        sortPriceLabel: (sort) => switch (sort) {
          FavoritesSort.priceLowHigh =>
            CustomerFavoritesStrings.sortPriceLowHigh,
          FavoritesSort.priceHighLow =>
            CustomerFavoritesStrings.sortPriceHighLow,
          FavoritesSort.alphabetical => CustomerFavoritesStrings.sortPrice,
        },
      ),
    );
  }
}
