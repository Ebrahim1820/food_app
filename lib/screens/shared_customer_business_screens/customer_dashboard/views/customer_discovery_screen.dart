// Generic customer discovery screen — category pills + section rows in
// discovery mode, 2-column grid in search mode. Reusable across markets
// (food, cosmetic, clothes, ...): a market wires up a
// CustomerDiscoveryConfig<T> pointing at its own controller/model and passes
// it in, see CustomerFoodScreen for the food-market wiring.
//
// Discovery mode (category = "all", no search text):
//   One horizontal row per non-empty category, from config.sections.
// Category mode (pill tapped, no search text):
//   Same row layout with one row.
// Search mode (user is typing):
//   2-column grid of matching items from config.searchResults.

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/common/stale_banner.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_category.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_section.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/customer_discovery_config.dart';
import 'package:get/get.dart';

class CustomerDiscoveryScreen<T> extends StatelessWidget {
  final CustomerDiscoveryConfig<T> config;

  const CustomerDiscoveryScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => config.searchText.value.isNotEmpty
          ? _SearchResultsView<T>(config: config)
          : _DiscoveryView<T>(config: config),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISCOVERY VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _DiscoveryView<T> extends StatelessWidget {
  final CustomerDiscoveryConfig<T> config;

  const _DiscoveryView({required this.config});

  @override
  Widget build(BuildContext context) {
    // Search input lives in the shared DashboardShell AppBar — this view
    // only owns the category pills and the section rows below it.
    return Column(
      children: [
        _CategoryPills<T>(config: config),

        Obx(
          () => config.isFromCache.value
              ? StaleBanner(onRefresh: config.onRefreshStale)
              : const SizedBox.shrink(),
        ),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: config.onPullToRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Obx(() {
                    final stateHeight =
                        (MediaQuery.of(context).size.height * 0.35).clamp(
                          150.0,
                          300.0,
                        );
                    if (config.sectionsLoading.value &&
                        config.sections.isEmpty) {
                      return SizedBox(
                        height: stateHeight,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (config.errorMessage.value.isNotEmpty &&
                        config.sections.isEmpty) {
                      return SizedBox(
                        height: stateHeight,
                        child: ErrorRetryWidget(
                          message: config.errorMessage.value,
                          onRetry: () => config.onPullToRefresh(),
                        ),
                      );
                    }
                    if (config.sections.isEmpty) {
                      return SizedBox(
                        height: stateHeight,
                        child: EmptyStateWidget(
                          icon: config.emptyIcon,
                          title: config.emptyTitle,
                          subtitle: config.emptySubtitle,
                        ),
                      );
                    }
                    return _SectionRows<T>(config: config);
                  }),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CATEGORY PILLS
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryPills<T> extends StatelessWidget {
  final CustomerDiscoveryConfig<T> config;

  const _CategoryPills({required this.config});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // "All" is always first; then one pill per category from the last full
      // discovery fetch. Using availableCategories (not sections) keeps the
      // full pill list visible even when the user has drilled into one category.
      final allPill = config.categories.first; // key == 'all'
      final sectionPills = config.availableCategories
          .map((key) => config.categories.firstWhereOrNull((c) => c.key == key))
          .whereType<MarketCategory>()
          .toList();

      return Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Row(
            children: [allPill, ...sectionPills].map((cat) {
              final isActive = config.selectedCategory.value == cat.key;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _CategoryPill(
                  cat: cat,
                  isActive: isActive,
                  onTap: () => config.onCategorySelected(cat.key),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}

class _CategoryPill extends StatelessWidget {
  final MarketCategory cat;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.cat,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.black.withValues(alpha: 0.06),
              blurRadius: isActive ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(
              cat.labelKey.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION ROWS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionRows<T> extends StatelessWidget {
  final CustomerDiscoveryConfig<T> config;

  const _SectionRows({required this.config});

  String _emoji(String category) =>
      config.categories.firstWhereOrNull((c) => c.key == category)?.emoji ??
      config.fallbackCategoryEmoji;

  String _label(String category, String backendLabel) {
    final match = config.categories.firstWhereOrNull((c) => c.key == category);
    return match != null ? match.labelKey.tr : backendLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final secs = config.sections;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: secs.map((section) {
          final isLoadingMore = config.loadingMoreSections.contains(
            section.category,
          );
          return _CategoryRow<T>(
            key: ValueKey(section.category),
            emoji: _emoji(section.category),
            title: _label(section.category, section.label),
            section: section,
            isLoadingMore: isLoadingMore,
            itemBuilder: config.itemBuilder,
            itemWidth: config.itemCardWidth,
            itemHeight: config.itemCardHeight,
            seeAllLabel: config.seeAllLabel,
            onSeeAll: config.selectedCategory.value == 'all'
                ? () => config.onCategorySelected(section.category)
                : null,
            onLoadMore: section.hasMore
                ? () => config.onLoadMoreSection(section.category)
                : null,
          );
        }).toList(),
      );
    });
  }
}

// ── Single horizontal category row ────────────────────────────────────────────

class _CategoryRow<T> extends StatefulWidget {
  final String emoji;
  final String title;
  final MarketSection<T> section;
  final bool isLoadingMore;
  final Widget Function(T item) itemBuilder;
  final double itemWidth;
  final double itemHeight;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;
  final VoidCallback? onLoadMore;

  const _CategoryRow({
    super.key,
    required this.emoji,
    required this.title,
    required this.section,
    required this.isLoadingMore,
    required this.itemBuilder,
    required this.itemWidth,
    required this.itemHeight,
    required this.seeAllLabel,
    this.onSeeAll,
    this.onLoadMore,
  });

  @override
  State<_CategoryRow<T>> createState() => _CategoryRowState<T>();
}

class _CategoryRowState<T> extends State<_CategoryRow<T>> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || widget.onLoadMore == null) return;
    final pos = _scroll.position;
    // pixels == 0 → initial mount, user hasn't scrolled yet.
    // maxScrollExtent <= 0 → content fits in viewport or layout not ready.
    if (pos.pixels <= 0 || pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 265) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.section.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (widget.section.total > items.length) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${widget.section.total}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.onSeeAll != null)
                GestureDetector(
                  onTap: widget.onSeeAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.seeAllLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: widget.itemHeight,
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              itemCount: items.length + (widget.isLoadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.only(
                    right: i < items.length - 1 ? 12 : 0,
                  ),
                  child: SizedBox(
                    width: widget.itemWidth,
                    child: widget.itemBuilder(items[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH RESULTS VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchResultsView<T> extends StatelessWidget {
  final CustomerDiscoveryConfig<T> config;

  const _SearchResultsView({required this.config});

  @override
  Widget build(BuildContext context) {
    // Search input lives in the shared DashboardShell AppBar — this view
    // only owns the results grid below it.
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (config.searchLoading.value && config.searchResults.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (config.errorMessage.value.isNotEmpty &&
                config.searchResults.isEmpty) {
              return ErrorRetryWidget(
                message: config.errorMessage.value,
                onRetry: config.onSearchRefresh,
              );
            }
            if (config.searchResults.isEmpty) {
              return EmptyStateWidget(
                icon: config.noResultsIcon,
                title: config.noResultsTitle,
                subtitle: config.noResultsSubtitle,
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: config.onSearchRefresh,
              child: CustomScrollView(
                controller: config.searchScrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: config.itemCardHeight,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            config.itemBuilder(config.searchResults[i]),
                        childCount: config.searchResults.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Obx(
                      () => config.searchLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
