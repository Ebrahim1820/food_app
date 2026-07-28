import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_category.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_section.dart';

/// Everything [CustomerDiscoveryScreen] needs to render one market's
/// customer-facing discovery screen: category pills + section rows in
/// discovery mode, a 2-column grid in search mode.
///
/// A market wires this up once (see CustomerFoodScreen) by pointing the Rx
/// fields at its own controller's reactive state and mapping its item model
/// to a card widget via [itemBuilder] — the screen itself has no knowledge
/// of what a "food offer" or "cosmetic product" is.
class CustomerDiscoveryConfig<T> {
  // ── Category browsing ──────────────────────────────────────────────────
  final List<MarketCategory> categories;
  final RxString selectedCategory;
  final RxList<String> availableCategories;
  final ValueChanged<String> onCategorySelected;
  final String fallbackCategoryEmoji;

  // ── Sections (discovery mode) ──────────────────────────────────────────
  final RxBool isFromCache;
  final VoidCallback onRefreshStale;
  final Future<void> Function() onPullToRefresh;
  final RxBool sectionsLoading;
  final RxList<MarketSection<T>> sections;
  final RxSet<String> loadingMoreSections;
  final void Function(String category) onLoadMoreSection;
  final String seeAllLabel;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  /// Empty string = no error. Non-empty shows [ErrorRetryWidget] (with a
  /// retry button wired to [onPullToRefresh]) instead of the plain empty
  /// state, so a failed fetch reads differently from a genuinely empty list.
  final RxString errorMessage;

  // ── Search mode ─────────────────────────────────────────────────────────
  final RxString searchText;
  final RxBool searchLoading;
  final RxBool searchLoadingMore;
  final RxList<T> searchResults;
  final ScrollController searchScrollController;
  final Future<void> Function() onSearchRefresh;
  final IconData noResultsIcon;
  final String noResultsTitle;
  final String noResultsSubtitle;

  // ── Item rendering — shared between section rows and the search grid ────
  final Widget Function(T item) itemBuilder;
  final double itemCardWidth;
  final double itemCardHeight;

  const CustomerDiscoveryConfig({
    required this.categories,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onCategorySelected,
    required this.fallbackCategoryEmoji,
    required this.isFromCache,
    required this.onRefreshStale,
    required this.onPullToRefresh,
    required this.sectionsLoading,
    required this.sections,
    required this.loadingMoreSections,
    required this.onLoadMoreSection,
    required this.seeAllLabel,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.errorMessage,
    required this.searchText,
    required this.searchLoading,
    required this.searchLoadingMore,
    required this.searchResults,
    required this.searchScrollController,
    required this.onSearchRefresh,
    required this.noResultsIcon,
    required this.noResultsTitle,
    required this.noResultsSubtitle,
    required this.itemBuilder,
    this.itemCardWidth = 265,
    this.itemCardHeight = 252,
  });
}
