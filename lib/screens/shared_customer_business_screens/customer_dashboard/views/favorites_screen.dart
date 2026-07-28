// Generic customer favorites screen — sort/category filter chips over a
// vertical list of the user's saved items. Reusable across markets the same
// way CustomerDiscoveryScreen<T> is: a market wiring layer (e.g. Food's
// FavoritesScreen) extracts values/callbacks from its own favorites
// controller into a [FavoritesConfig], and owns anything market-specific
// this screen has no business knowing about — the actual favorites
// controller, persistence, restock alerts, and the row widget itself (via
// [FavoritesConfig.itemBuilder]).
//
// This file never imports a market model, market controller, or a market's
// translation keys — it only reads/writes the plain Rx fields and callbacks
// handed to it.

import 'package:flutter/material.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/common/filter_chip_widget.dart';
import 'package:food_app/widgets/common/stale_banner.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:get/get.dart';

/// Ordered, de-duplicated non-empty category keys present in [items] — the
/// same extraction every market's [FavoritesConfig.availableCategories]
/// needs, factored out so wiring layers don't each reimplement the loop.
List<String> uniqueCategories<T>(
  List<T> items,
  String Function(T item) categoryOf,
) {
  final seen = <String>{};
  final keys = <String>[];
  for (final item in items) {
    final category = categoryOf(item);
    if (category.isNotEmpty && seen.add(category)) keys.add(category);
  }
  return keys;
}

/// Everything [FavoritesScreen] needs to render one market's favorites list.
/// A market wires this up once (see Food's FavoritesScreen) by pointing the
/// Rx fields at its own favorites controller and mapping its item model to a
/// row widget via [itemBuilder].
class FavoritesConfig<T> {
  // ── Raw favorites (unfiltered) ──────────────────────────────────────────
  final RxList<T> rawItems;

  /// Pure function of the current search/sort/category state onto
  /// [rawItems] — called inside an `Obx`, so it re-runs whenever any of
  /// [searchQuery], [sortOrder] or [categoryFilter] change, exactly like
  /// [rawItems] itself.
  final List<T> Function(List<T> rawItems) filterAndSort;

  final RxString searchQuery;
  final Rx<FavoritesSort> sortOrder;
  final RxString categoryFilter;

  /// Ordered, de-duplicated category keys actually present in [rawItems] —
  /// NOT including 'all'; the widget always prepends its own "All" chip.
  final List<String> Function(List<T> rawItems) availableCategories;
  final String Function(String categoryKey) categoryLabel;

  final RxBool isFromCache;
  final VoidCallback onRefreshStale;

  final Widget Function(T item) itemBuilder;

  // ── Empty states ─────────────────────────────────────────────────────────
  final String emptyTitle;
  final String emptySubtitle;
  final String browseButtonLabel;
  final VoidCallback onBrowse;

  final String filteredEmptyTitle;
  final String filteredEmptySubtitle;
  final String clearFiltersButtonLabel;
  final VoidCallback onClearFilters;

  // ── Chip copy ────────────────────────────────────────────────────────────
  final String categoryAllLabel;
  final String sortAlphabeticalLabel;
  final String Function(FavoritesSort currentSort) sortPriceLabel;

  const FavoritesConfig({
    required this.rawItems,
    required this.filterAndSort,
    required this.searchQuery,
    required this.sortOrder,
    required this.categoryFilter,
    required this.availableCategories,
    required this.categoryLabel,
    required this.isFromCache,
    required this.onRefreshStale,
    required this.itemBuilder,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.browseButtonLabel,
    required this.onBrowse,
    required this.filteredEmptyTitle,
    required this.filteredEmptySubtitle,
    required this.clearFiltersButtonLabel,
    required this.onClearFilters,
    required this.categoryAllLabel,
    required this.sortAlphabeticalLabel,
    required this.sortPriceLabel,
  });
}

class FavoritesScreen<T> extends StatelessWidget {
  final FavoritesConfig<T> config;

  const FavoritesScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterChips<T>(config: config),
        Obx(
          () => config.isFromCache.value
              ? StaleBanner(onRefresh: config.onRefreshStale)
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: Obx(() {
            final raw = config.rawItems.toList();
            final filtered = config.filterAndSort(raw);

            if (raw.isEmpty) {
              return _EmptyState<T>(config: config, noFavorites: true);
            }
            if (filtered.isEmpty) {
              return _EmptyState<T>(config: config, noFavorites: false);
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => config.itemBuilder(filtered[index]),
            );
          }),
        ),
      ],
    );
  }
}

// ── Sort + category filter chips ─────────────────────────────────────────────

class _FilterChips<T> extends StatelessWidget {
  final FavoritesConfig<T> config;
  const _FilterChips({required this.config});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sort = config.sortOrder.value;
      final isPriceActive =
          sort == FavoritesSort.priceLowHigh ||
          sort == FavoritesSort.priceHighLow;
      final priceLabel = config.sortPriceLabel(sort);
      final selectedCat = config.categoryFilter.value;
      final categoryKeys = config.availableCategories(config.rawItems);

      return Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sort row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  FilterChipWidget(
                    label: config.sortAlphabeticalLabel,
                    selected: sort == FavoritesSort.alphabetical,
                    onTap: () =>
                        config.sortOrder.value = FavoritesSort.alphabetical,
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    label: priceLabel,
                    selected: isPriceActive,
                    onTap: () => config.sortOrder.value =
                        sort == FavoritesSort.priceLowHigh
                        ? FavoritesSort.priceHighLow
                        : FavoritesSort.priceLowHigh,
                  ),
                ],
              ),
            ),
            // Category row — only the categories actually present among the
            // current favorites; hidden entirely when there's one or none.
            if (categoryKeys.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    FilterChipWidget(
                      label: config.categoryAllLabel,
                      selected: selectedCat == 'all',
                      onTap: () => config.categoryFilter.value = 'all',
                    ),
                    ...categoryKeys.map(
                      (key) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChipWidget(
                          label: config.categoryLabel(key),
                          selected: selectedCat == key,
                          onTap: () => config.categoryFilter.value = key,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Empty / filtered-empty state ─────────────────────────────────────────────

class _EmptyState<T> extends StatelessWidget {
  final FavoritesConfig<T> config;
  final bool noFavorites;
  const _EmptyState({required this.config, required this.noFavorites});

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        config.searchQuery.value.isNotEmpty ||
        config.categoryFilter.value != 'all';

    return EmptyStateWidget(
      icon: noFavorites ? Icons.favorite_border : Icons.filter_list_off,
      title: noFavorites ? config.emptyTitle : config.filteredEmptyTitle,
      subtitle: noFavorites
          ? config.emptySubtitle
          : config.filteredEmptySubtitle,
      action: noFavorites
          ? CustomDynamicButton(
              borderRadius: 14,
              icon: Icons.explore_outlined,
              label: config.browseButtonLabel,
              onPressed: config.onBrowse,
            )
          : (!noFavorites && hasFilters)
          ? CustomDynamicButton(
              variant: CustomButtonVariant.text,
              label: config.clearFiltersButtonLabel,
              onPressed: config.onClearFilters,
            )
          : null,
    );
  }
}
