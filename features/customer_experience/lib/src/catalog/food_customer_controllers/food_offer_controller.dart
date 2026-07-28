import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:profile/profile.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';
import 'package:models/models.dart';
import 'package:notification/notification.dart';

/// Controls the customer home screen: sections mode (discovery + single-category)
/// and search mode (full-text across all categories).
///
/// Sections mode  — uses GET /api/products/sections/food (initial) and
///                  GET /api/products/sections/food/{cat}?page=N (load more per row).
/// Search mode    — uses GET /api/products?market=food&title=... (flat paginated list).
class FoodOfferController extends GetxController {
  final FoodOfferService service;
  FoodOfferController(this.service);

  static const _tag = 'FoodOfferController';

  // ── Sections state (discovery + single-category) ──────────────────────────
  final sections = <FoodSectionModel>[].obs;
  final sectionsLoading = false.obs;
  final isFromCache = false.obs;

  /// Stable list of category keys from the last full discovery fetch.
  /// Updated only by [fetchSections], NOT by [fetchCategorySection], so the
  /// category pill bar keeps showing all options while the user drills into
  /// a single category.
  final availableCategories = <String>[].obs;

  /// Categories that are currently fetching their next page.
  final loadingMoreSections = <String>{}.obs;

  // ── Search / single-category filter state ─────────────────────────────────
  final selectedCategory = 'all'.obs;
  final selectedSort = OfferSort.newest.obs;
  final priceAscending = true.obs;

  // ── Search results state (flat list, only active while typing) ─────────────
  final offers = <FoodOfferModel>[].obs;
  final filteredOffers = <FoodOfferModel>[].obs;
  final loading = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  final loadingMore = false.obs;
  final fetchError = ''.obs;
  static const int itemsPerPage = 20;

  // NOTE: no TextEditingController here on purpose. This controller is
  // `fenix: true` (GetX may dispose + later recreate it independently of
  // any screen), but the search field lives in MainNavigationScreen's
  // AppBar, which stays mounted across every tab switch — a shorter-lived
  // fenix controller owning a TextEditingController that a longer-lived
  // widget renders is exactly what caused
  // "Once you have called dispose()... it can no longer be used" here.
  // MainNavigationScreen owns the TextEditingController itself and passes
  // it into CustomerFoodScreen; only the reactive text value lives here.
  final searchText = ''.obs;
  final scrollController = ScrollController();

  Timer? _debounce;
  int _requestId = 0;

  // ── Real-time updates (Mercure) ─────────────────────────────────────────
  static const _mercure = MercureService();
  StreamSubscription? _mercureSub;
  Worker? _cityWorker;

  /// The city slug the current [_mercureSub] is subscribed to, so a
  /// selected-address change that doesn't actually change city (e.g.
  /// switching between two addresses in the same city) doesn't needlessly
  /// tear down and reopen the SSE connection.
  String? _subscribedCitySlug;

  static const _cacheKey = 'food_sections_v1';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    _loadCachedSections();
    fetchSections();
    scrollController.addListener(_onScroll);
    _watchCityForMercure();
    super.onInit();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _mercureSub?.cancel();
    _cityWorker?.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// New-offer alerts are now scoped to a city (`food-products/city/{slug}`) —
  /// "current city" has no backend field, so this app derives it from the
  /// customer's selected delivery address. Re-subscribes whenever that
  /// address (and therefore its city) changes.
  void _watchCityForMercure() {
    final addressCtrl = Get.find<AddressController>();
    _resubscribeForCity(addressCtrl.selectedAddress.value?.city);
    _cityWorker = ever(addressCtrl.selectedAddress, (address) {
      _resubscribeForCity(address?.city);
    });
  }

  void _resubscribeForCity(String? city) {
    if (city == null || city.isEmpty) return;
    final slug = MercureService.citySlug(city);
    if (slug.isEmpty || slug == _subscribedCitySlug) return;

    _mercureSub?.cancel();
    _subscribedCitySlug = slug;
    // Live counterpart to the 'new_offer' FCM push handled in
    // PushNotificationService — same refreshForNewOffer() hook, just fired
    // the moment the backend publishes to Mercure instead of waiting on FCM.
    _mercureSub = _mercure.subscribeToFoodOffers(
      citySlug: slug,
      onOffer: (offer) {
        AppLogger.info(
          _tag,
          'Mercure: new offer "${offer.title}" — refreshing',
        );
        refreshForNewOffer();
      },
    );
  }

  // ── Cache ─────────────────────────────────────────────────────────────────

  void _loadCachedSections() {
    final cached = DataCacheService.load(
      _cacheKey,
      (json) => (json as List)
          .map((e) => FoodSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (cached != null && cached.isNotEmpty) {
      sections.assignAll(cached);
      availableCategories.assignAll(cached.map((s) => s.category));
      isFromCache.value = true;
    }
  }

  Future<void> _saveSectionsCache(List<FoodSectionModel> data) async {
    await DataCacheService.save(
      _cacheKey,
      data.map((s) => s.toJson()).toList(),
    );
  }

  // ── Sections fetch ────────────────────────────────────────────────────────

  /// Loads all non-empty category sections in one request (discovery mode).
  /// Also used on pull-to-refresh.
  Future<void> fetchSections() async {
    sectionsLoading.value = true;
    fetchError.value = '';
    try {
      final result = await service.getSections();
      sections.assignAll(result);
      availableCategories.assignAll(result.map((s) => s.category));
      isFromCache.value = false;
      if (result.isNotEmpty) await _saveSectionsCache(result);
    } catch (e, st) {
      AppLogger.error(_tag, 'fetchSections failed', error: e, stackTrace: st);
      if (sections.isEmpty) fetchError.value = 'Could not load offers';
    } finally {
      sectionsLoading.value = false;
    }
  }

  /// Loads page 1 of a single category, replacing sections with that one row.
  /// Called when the user taps a category pill (not "All").
  Future<void> fetchCategorySection(String category) async {
    sectionsLoading.value = true;
    fetchError.value = '';
    sections.clear();
    try {
      final result = await service.getSectionPage(category, 1);
      sections.assignAll([result]);
      isFromCache.value = false;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchCategorySection($category) failed',
        error: e,
        stackTrace: st,
      );
      fetchError.value = 'Could not load offers';
    } finally {
      sectionsLoading.value = false;
    }
  }

  /// Appends the next page of [category] to its existing section row.
  /// Called when the user scrolls to the right edge of a horizontal row.
  Future<void> loadSectionPage(String category) async {
    final idx = sections.indexWhere((s) => s.category == category);
    if (idx == -1) return;
    final section = sections[idx];
    if (!section.hasMore || loadingMoreSections.contains(category)) return;

    loadingMoreSections.add(category);
    try {
      final next = await service.getSectionPage(
        category,
        section.nextPage!,
        limit: section.limit,
      );
      sections[idx] = section.appendPage(
        more: next.items,
        hasMore: next.hasMore,
        nextPage: next.nextPage,
        limit: next.limit,
      );
      // Trigger reactivity for the list element change.
      sections.refresh();
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'loadSectionPage($category) failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      loadingMoreSections.remove(category);
    }
  }

  // ── Category pill selection ───────────────────────────────────────────────

  void onCategorySelected(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    if (category == 'all') {
      fetchSections();
    } else {
      fetchCategorySection(category);
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void onSearchChanged(String value) {
    searchText.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      resetPagination();
      final int currentRequest = ++_requestId;
      fetchOffers(requestId: currentRequest);
    });
  }

  Future<void> fetchOffers({bool loadMore = false, int? requestId}) async {
    if (loadMore && (!hasMore.value || loadingMore.value)) return;

    if (loadMore) {
      loadingMore.value = true;
    } else {
      loading.value = true;
      resetPagination();
    }

    try {
      final sorting = _getSorting();
      final result = await service.getOffers(
        title: searchText.value.trim().isEmpty ? null : searchText.value.trim(),
        category: selectedCategory.value == 'all'
            ? null
            : selectedCategory.value,
        orderField: sorting.$1,
        orderDirection: sorting.$2,
        page: currentPage.value,
        itemsPerPage: itemsPerPage,
      );

      if (requestId != null && requestId != _requestId) return;

      if (loadMore) {
        offers.value = [...offers, ...result];
      } else {
        offers.assignAll(result);
      }

      _applyFilters();
      fetchError.value = '';
      hasMore.value = result.isNotEmpty && result.length >= itemsPerPage;
      if (result.isNotEmpty) currentPage.value++;
    } catch (e, st) {
      AppLogger.error(_tag, 'fetchOffers failed', error: e, stackTrace: st);
      if (offers.isEmpty) fetchError.value = 'Could not load offers';
    } finally {
      loading.value = false;
      loadingMore.value = false;
    }
  }

  // ── Quantity restore (after order cancel) ────────────────────────────────

  /// Restores available quantities in every section row without a full refetch.
  ///
  /// Weight-based offers keep `quantityAvailable` at null (see the
  /// `.draftWeight` constructor) and track stock via `weightAvailableKg`
  /// instead — this used to unconditionally bump `quantityAvailable` for
  /// every matched offer, which both left weight-based offers' real stock
  /// field (`weightAvailableKg`) never restored on cancel AND incorrectly
  /// gave them a non-null `quantityAvailable` they're not supposed to have.
  void restoreQuantities(List<OrderItemModel> items) {
    AppLogger.info(
      _tag,
      'restoreQuantities: crediting ${items.length} item(s) for offer id(s) '
      '${items.map((i) => i.foodOffer.id).toList()} across '
      '${sections.length} section(s) / ${offers.length} flat offer(s)',
    );

    FoodOfferModel apply(FoodOfferModel offer) {
      final match = items.firstWhereOrNull((i) => i.foodOffer.id == offer.id);
      if (match == null) return offer;
      return offer.isWeightBased
          ? offer.copyWith(
              weightAvailableKg:
                  (offer.weightAvailableKg ?? 0) + (match.weightTotalKg ?? 0),
            )
          : offer.copyWith(
              quantityAvailable:
                  (offer.quantityAvailable ?? 0) + match.quantity,
            );
    }

    var sectionsMatched = 0;
    for (int si = 0; si < sections.length; si++) {
      final section = sections[si];
      bool changed = false;
      final updatedItems = section.items.map((offer) {
        final updated = apply(offer);
        if (!identical(updated, offer)) changed = true;
        return updated;
      }).toList();
      if (changed) {
        sectionsMatched++;
        sections[si] = FoodSectionModel(
          category: section.category,
          label: section.label,
          total: section.total,
          limit: section.limit,
          hasMore: section.hasMore,
          nextPage: section.nextPage,
          items: updatedItems,
        );
      }
    }
    sections.refresh();

    // Also update flat search results if visible.
    var offersMatched = 0;
    for (final item in items) {
      final idx = offers.indexWhere((o) => o.id == item.foodOffer.id);
      if (idx != -1) {
        offersMatched++;
        offers[idx] = apply(offers[idx]);
      }
    }
    _applyFilters();

    AppLogger.info(
      _tag,
      'restoreQuantities: matched in $sectionsMatched section row(s), '
      '$offersMatched flat offer row(s) — if both are 0, the offer(s) '
      "aren't currently loaded in this controller's cached lists at all "
      '(e.g. a different/uncached category), so nothing visible changes '
      'until the next real fetch',
    );
  }

  /// Decrements available stock for [offerId] in every cached section/search
  /// row right after an order is placed, so the home/search screens reflect
  /// the new stock immediately instead of showing the stale pre-order number
  /// until the next pull-to-refresh or app restart. Mirrors
  /// [restoreQuantities] but subtracts (clamped at 0) instead of adding.
  void reduceQuantity(int offerId, {required int quantity, double? weightKg}) {
    FoodOfferModel apply(FoodOfferModel offer) {
      final qty = offer.quantityAvailable;
      final weight = offer.weightAvailableKg;
      return offer.copyWith(
        quantityAvailable: qty == null ? null : _clampMin0(qty - quantity),
        weightAvailableKg: (weight == null || weightKg == null)
            ? weight
            : _clampMin0Double(weight - weightKg),
      );
    }

    for (int si = 0; si < sections.length; si++) {
      final section = sections[si];
      var changed = false;
      final updatedItems = section.items.map((offer) {
        if (offer.id != offerId) return offer;
        changed = true;
        return apply(offer);
      }).toList();
      if (changed) {
        sections[si] = FoodSectionModel(
          category: section.category,
          label: section.label,
          total: section.total,
          limit: section.limit,
          hasMore: section.hasMore,
          nextPage: section.nextPage,
          items: updatedItems,
        );
      }
    }
    sections.refresh();

    final idx = offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) offers[idx] = apply(offers[idx]);
    _applyFilters();
  }

  int _clampMin0(int v) => v < 0 ? 0 : v;
  double _clampMin0Double(double v) => v < 0 ? 0 : v;

  /// Re-fetches whatever's currently on screen so a new offer shows up
  /// without the user having to pull-to-refresh. Called when a `new_offer`
  /// push arrives.
  ///
  /// Deliberately skipped while the user is actively searching (`searchText`
  /// non-empty) — yanking their search results out from under them for an
  /// unrelated background event would be jarring, and the new offer may not
  /// even match what they typed. Only refreshes the section/category
  /// actually visible right now, not every category at once.
  void refreshForNewOffer() {
    if (searchText.value.trim().isNotEmpty) return;
    if (selectedCategory.value == 'all') {
      fetchSections();
    } else {
      fetchCategorySection(selectedCategory.value);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void resetPagination() {
    currentPage.value = 1;
    hasMore.value = true;
    offers.clear();
    filteredOffers.clear();
  }

  void _applyFilters() {
    final now = DateTime.now();
    List<FoodOfferModel> list = List.from(offers);
    list = list.where((o) => !now.isAfter(o.endTime)).toList();
    list = list
        .where(
          (o) => o.isWeightBased
              ? (o.weightAvailableKg ?? 0) > 0
              : (o.quantityAvailable ?? 0) > 0,
        )
        .toList();
    filteredOffers.assignAll(list);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (loadingMore.value || !hasMore.value) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      fetchOffers(loadMore: true);
    }
  }

  (String?, String?) _getSorting() {
    switch (selectedSort.value) {
      case OfferSort.newest:
        return ('createdAt', 'desc');
      case OfferSort.price:
        return ('price', priceAscending.value ? 'asc' : 'desc');
      case OfferSort.popular:
        return ('quantityAvailable', 'desc');
    }
  }
}
