// lib/screens/business/business_menu_screen.dart
//
// Business partner's "Menu" tab — the list of surplus offers they've published.
// Includes live search and filter chips (status + sort) powered by
// BusinessOfferController and the shared SearchFilterBar widget.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:food_app/controllers/food_controllers/food_business_controllers/business_offer_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:models/models.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/screens/food_teil/business_views/business_offer_detail_screen.dart';
import 'package:food_app/screens/food_teil/business_views/create_food_offer_screen.dart';
import 'package:food_app/widgets/common/confirm_dialog.dart';
import 'package:food_app/screens/food_teil/business_views/search_filter_bar.dart';
import 'package:food_app/widgets/common/stale_banner.dart';

/// The partner's "Menu" tab: a searchable, filterable list of surplus offers.
///
/// Layout:
///   Header row (count + "New" button)
///   └─ SearchFilterBar   ← search + status / sort chips (reusable widget)
///   └─ Offer list        ← pull-to-refresh, empty & error states
///
/// Converted to [StatefulWidget] only to own the [TextEditingController]
/// lifecycle. All business logic and list state live in [BusinessOfferController].
/// Lives inside the dashboard's [IndexedStack], so it has no Scaffold/AppBar.
class BusinessMenuScreen extends StatefulWidget {
  const BusinessMenuScreen({super.key, required this.businessPartnerId});

  final int businessPartnerId;

  @override
  State<BusinessMenuScreen> createState() => _BusinessMenuScreenState();
}

class _BusinessMenuScreenState extends State<BusinessMenuScreen> {
  // ── Palette (kept in sync with the dashboard) ────────────────────────────

  // ── Controller & local UI state ──────────────────────────────────────────

  final BusinessOfferController c = Get.find<BusinessOfferController>();

  /// Owns the text inside the search field.
  final TextEditingController _searchCtrl = TextEditingController();

  /// Persists scroll position across Obx rebuilds (stored in State, not rebuilt).
  final ScrollController _scrollCtrl = ScrollController();

  /// The last confirmed non-zero partner ID. Set once on initState/didUpdateWidget
  /// and never cleared, so _openCreate always has a valid ID even if the
  /// controller's partner is temporarily null.
  int _cachedPartnerId = 0;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  int _resolvePartnerId() {
    final fromController = Get.find<BusinessPartnerController>().partnerId;
    return fromController != 0 ? fromController : widget.businessPartnerId;
  }

  void _tryLoad(int id) {
    if (id != 0) {
      _cachedPartnerId = id;
      c.ensureOffersLoaded(id);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryLoad(_resolvePartnerId()),
    );
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      c.loadMoreOffers(_cachedPartnerId);
    }
  }

  @override
  void didUpdateWidget(BusinessMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newId = _resolvePartnerId();
    if (newId != 0 && newId != oldWidget.businessPartnerId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad(newId));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Stack(
      children: [
        Container(
          color: AppColors.gray50,
          // Header + search/filter bar are fixed Column children (outside the
          // scroll view) so only the offer list scrolls underneath them —
          // matching business_orders_screen.dart's fixed filter bar pattern.
          child: Column(
            children: [
              _header(isLandscape),
              Obx(_buildSearchBar),
              Obx(
                () => c.isFromCache.value
                    ? StaleBanner(
                        onRefresh: () => c.fetchMyOffers(
                          _cachedPartnerId != 0
                              ? _cachedPartnerId
                              : _resolvePartnerId(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Obx(() {
                  final isLoading =
                      c.isLoadingOffers.value && c.myOffers.isEmpty;
                  final hasError =
                      c.listError.value.isNotEmpty && c.myOffers.isEmpty;
                  final offers = c.filteredOffers;

                  return RefreshIndicator(
                    color: AppColors.successDark,
                    onRefresh: () => c.fetchMyOffers(
                      _cachedPartnerId != 0
                          ? _cachedPartnerId
                          : _resolvePartnerId(),
                    ),
                    child: CustomScrollView(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (isLoading)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (hasError)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _errorState(),
                          )
                        else if (offers.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _emptyState(),
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            sliver: SliverList.builder(
                              itemCount: offers.length,
                              itemBuilder: (_, i) => _offerCard(offers[i]),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Obx(
                              () => c.isLoadingMoreOffers.value
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox(height: 96),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        // Sticky "New Offer" FAB — always visible even when the list is scrolled.
        Positioned(
          right: 16,
          bottom: bottomInset + 16,
          child: FloatingActionButton.extended(
            heroTag: null,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              BusinessOfferMenuStrings.newOfferButton,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            onPressed: _openCreate,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SearchFilterBar(
      searchController: _searchCtrl,
      onSearch: (v) => c.offerSearch.value = v,
      searchHint: BusinessOfferMenuStrings.searchHint,
      activeSearchQuery: c.offerSearch.value,
      filterGroups: [
        [
          FilterChipOption(
            label: BusinessOfferMenuStrings.sortOldestFirst,
            selected: c.offerSort.value == OfferSortOrder.oldest,
            onTap: () =>
                c.offerSort.value = c.offerSort.value == OfferSortOrder.oldest
                ? OfferSortOrder.newest
                : OfferSortOrder.oldest,
          ),
        ],
        [
          for (final status in OfferStatusFilter.values.where(
            (s) => s != OfferStatusFilter.all,
          ))
            FilterChipOption(
              label: status.label,
              selected: c.offerStatusFilter.value == status,
              onTap: () => c.offerStatusFilter.value =
                  c.offerStatusFilter.value == status
                  ? OfferStatusFilter.all
                  : status,
            ),
        ],
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _header(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLandscape ? 8 : 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shows the total raw count (not the filtered count) so the partner
          // always knows how many offers they've published.
          Expanded(
            child: Obx(
              () => Text(
                BusinessOfferMenuStrings.offerCount(c.myOffers.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isLandscape ? 17 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                  : null,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(BusinessOfferMenuStrings.newOfferButton),
            onPressed: _openCreate,
          ),
        ],
      ),
    );
  }

  // ── Offer card ───────────────────────────────────────────────────────────

  Widget _offerCard(FoodOfferModel o) {
    final left = o.quantityAvailable ?? 0;
    final total = o.quantityTotal ?? 0;
    final soldOut = o.isWeightBased
        ? (o.weightAvailableKg ?? 0) <= 0
        : left <= 0;
    final inactive =
        o.status == 'cancelled' ||
        o.status == 'expired' ||
        o.status == 'inactive' ||
        o.status == 'hidden';

    return Opacity(
      opacity: inactive ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(o),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumb(o),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row + status badge + delete button.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              o.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _statusBadge(o.status),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              color: AppColors.error,
                              tooltip: BusinessOfferMenuStrings.deleteTooltip,
                              // stopPropagation: prevent the card's onTap from
                              // also firing when the delete icon is tapped.
                              onPressed: () => _confirmDeleteOffer(o),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _prettyCategory(o.category),
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Pickup window row.
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 15,
                            color: AppColors.gray600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _window(o.startTime, o.endTime),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.gray600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Price + quantity pill.
                      Row(
                        children: [
                          Text(
                            o.isWeightBased
                                ? CurrencyFormatter.perKg(o.pricePerKg ?? 0)
                                : _money(o.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successDark,
                            ),
                          ),
                          const Spacer(),
                          o.isWeightBased
                              ? _weightPill(
                                  o.weightAvailableKg ?? 0,
                                  o.weightTotalKg ?? 0,
                                  soldOut,
                                )
                              : _qtyPill(left, total, soldOut),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Card sub-widgets ─────────────────────────────────────────────────────

  Widget _thumb(FoodOfferModel offer) {
    final url = offer.images.isNotEmpty ? offer.images.first.url : null;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          placeholder: (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, _) => _iconThumb(offer.category),
        ),
      );
    }
    return _iconThumb(offer.category);
  }

  Widget _iconThumb(String category) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.successDark.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _categoryIcon(category),
        color: AppColors.successDark,
        size: 30,
      ),
    );
  }

  Widget _qtyPill(int left, int total, bool soldOut) {
    final color = soldOut ? AppColors.gray400 : AppColors.navy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        soldOut
            ? OfferStatusLabels.soldOut
            : BusinessOfferMenuStrings.quantityLeft(left, total),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _weightPill(double availableKg, double totalKg, bool soldOut) {
    final color = soldOut ? AppColors.gray400 : AppColors.navy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        soldOut
            ? OfferStatusLabels.soldOut
            : '${CurrencyFormatter.localizeDigits(availableKg.toStringAsFixed(1))}/${CurrencyFormatter.localizeDigits(totalKg.toStringAsFixed(1))} ${CurrencyFormatter.isFarsi ? CurrencyFormatter.faKgUnit : 'kg'}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'active' => (OfferStatusLabels.active, AppColors.successDark),
      'scheduled' => (OfferStatusLabels.scheduled, AppColors.infoDark),
      'sold_out' => (OfferStatusLabels.soldOut, AppColors.gray400),
      'expired' => (OfferStatusLabels.expired, AppColors.errorDark),
      'cancelled' => (OfferStatusLabels.cancelled, AppColors.warningDark),
      'inactive' => (OfferStatusLabels.inactive, AppColors.warningDark),
      'hidden' => (OfferStatusLabels.hidden, AppColors.warningDeep),
      _ => (status, AppColors.gray600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  // ── Empty / error states ─────────────────────────────────────────────────

  Widget _emptyState() {
    // Two different messages: nothing published vs. nothing matches the filter.
    final isFiltered =
        c.offerSearch.value.isNotEmpty ||
        c.offerStatusFilter.value != OfferStatusFilter.all;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.storefront_outlined,
            size: 64,
            color: AppColors.gray600,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isFiltered
                  ? BusinessOfferMenuStrings.noOffersFiltered
                  : BusinessOfferMenuStrings.noOffersYet,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              isFiltered
                  ? BusinessOfferMenuStrings.filteredEmptyHint
                  : BusinessOfferMenuStrings.emptyHint,
              style: const TextStyle(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 18),
          if (isFiltered)
            Center(
              child: CustomDynamicButton(
                label: BusinessOfferMenuStrings.clearFilters,
                onPressed: c.clearOfferFilters,
                variant: CustomButtonVariant.outlined,
              ),
            )
          else
            Center(
              child: CustomDynamicButton(
                label: BusinessOfferMenuStrings.addFirstOffer,
                onPressed: _openCreate,
                icon: Icons.add,
                accentColor: AppColors.successDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: AppColors.gray600,
          ),
          const SizedBox(height: 12),
          Text(
            c.listError.value,
            style: const TextStyle(color: AppColors.gray600),
          ),
          const SizedBox(height: 14),
          CustomDynamicButton(
            label: BusinessOfferMenuStrings.retryButton,
            onPressed: () => c.fetchMyOffers(
              _cachedPartnerId != 0 ? _cachedPartnerId : _resolvePartnerId(),
            ),
            variant: CustomButtonVariant.outlined,
          ),
        ],
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Future<void> _confirmDeleteOffer(FoodOfferModel offer) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.delete_forever_rounded,
      title: BusinessOfferDialogStrings.deleteTitle,
      subtitle: BusinessOfferDialogStrings.offerSubtitle(offer.title),
      body: BusinessOfferDialogStrings.deleteBody,
      confirmLabel: BusinessOfferDialogStrings.deleteConfirmLabel,
      cancelLabel: BusinessOfferDialogStrings.deleteCancelLabel,
    );
    if (confirmed != true) return;

    final ok = await c.deleteOffer(offer.id);
    if (!mounted) return;
    if (!ok) {
      AppSnackbar.error(
        BusinessOfferMenuStrings.errorSnackTitle,
        c.updateErrorText.isNotEmpty
            ? c.updateErrorText
            : BusinessOfferMenuStrings.couldNotDelete,
      );
    }
  }

  Future<void> _openDetail(FoodOfferModel offer) async {
    // updateOffer / deleteOffer already update myOffers in-place so a re-fetch
    // isn't needed — but we still await the result so the menu rebuilds once
    // the detail screen pops (GetX re-renders the Obx list automatically).
    await Get.to<bool>(() => BusinessOfferDetailScreen(offer: offer));
  }

  Future<void> _openCreate() async {
    // Use the cached ID (set when offers first loaded) so we always have the
    // correct partner ID even if the controller's partner is temporarily null.
    final id = _cachedPartnerId != 0 ? _cachedPartnerId : _resolvePartnerId();
    if (id == 0) {
      AppSnackbar.success(
        BusinessOfferMenuStrings.notReadyTitle,
        BusinessOfferMenuStrings.notReadyBody,
      );
      return;
    }
    final created = await Get.to<bool>(
      () => CreateFoodOfferScreen(businessPartnerId: id),
    );
    if (created == true) c.fetchMyOffers(id);
  }

  // ── Formatting helpers ───────────────────────────────────────────────────

  String _money(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return CurrencyFormatter.format(d);
  }

  String _window(DateTime s, DateTime e) {
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    final day = DateFormat('MMM d');
    final time = DateFormat('HH:mm');
    return sameDay
        ? '${day.format(s)}, ${time.format(s)}–${time.format(e)}'
        : '${day.format(s)} ${time.format(s)} → ${day.format(e)} ${time.format(e)}';
  }

  String _prettyCategory(String c) => c
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
    'fast_food' || 'fastfood' => Icons.fastfood_outlined,
    'pizza' => Icons.local_pizza_outlined,
    'bakery' || 'bread_pastries' => Icons.bakery_dining_outlined,
    'restaurant' || 'meals' || 'meal' => Icons.restaurant,
    'supermarket' || 'groceries' || 'grocery' => Icons.shopping_cart_outlined,
    'cafe' || 'caffe' => Icons.local_cafe_outlined,
    'fruits_vegetables' || 'vegetables' || 'fruit' => Icons.eco_outlined,
    'hot_drinks' || 'drinks' => Icons.local_drink_outlined,
    'cheese_dairy' => Icons.egg_alt_outlined,
    'butcher' => Icons.set_meal_outlined,
    'fish' => Icons.set_meal_outlined,
    'deli_catering' => Icons.lunch_dining_outlined,
    'flowers' || 'florist' => Icons.local_florist_outlined,
    'salads' || 'salad' || 'dessert' => Icons.spa_outlined,
    _ => Icons.fastfood_outlined,
  };
}
