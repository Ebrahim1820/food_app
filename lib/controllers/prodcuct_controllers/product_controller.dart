import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:food_app/models/product_models/product_section_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_item_model.dart';
import 'package:food_app/profile_and_orders/profile/controllers/address_controller.dart';
import 'package:food_app/services/data_cache_service.dart';
import 'package:food_app/services/mercure_service.dart';
import 'package:food_app/services/product_service.dart';
import 'package:food_app/utils/app_logger.dart';

/// Controls customer product discovery, search, and section pagination for a
/// specific [market] (e.g., 'cosmetic', 'grocery'). Favoriting is handled by
/// the market-agnostic `FavoritesOfferController`, not this class.
///
/// **Modes of Operation:**
/// * **Sections/Discovery Mode:** Uses `GET /api/products/sections/{market}` to load multi-category horizontal rows.
/// * **Single-Category Row Mode:** Uses `GET /api/products/sections/{market}/{cat}?page=1` when filtering by pill.
/// * **Category Row Infinite Scroll:** Uses `GET /api/products/sections/{market}/{cat}?page=N` when scrolling right.
/// * **Search / Flat Mode:** Uses `GET /api/products?market=...&title=...` for full-text search and filtering.
///
/// **Real-Time & Local Cache:**
/// * Listens to Mercure SSE streams scoped by market and delivery city (`{market}-{citySlug}`).
/// * Caches discovery sections using market-isolated storage keys (`product_sections_{market}_v1`).
class ProductController extends GetxController {
  final ProductService service;
  final String market;

  ProductController(this.service, {required this.market});

  static const _tag = 'ProductController';

  // ── Sections State (Discovery + Horizontal Rows) ──────────────────────────

  /// Categorized section rows rendered on the discovery screen.
  final sections = <ProductSectionModel>[].obs;

  /// True while initial section rows are loading from the network.
  final sectionsLoading = false.obs;

  /// True if the currently visible [sections] were restored from local disk cache.
  final isFromCache = false.obs;

  /// Stable list of category keys fetched from the initial discovery call.
  /// Kept intact during single-category filtering so category pills remain available.
  final availableCategories = <String>[].obs;

  /// Set of category keys currently fetching next horizontal pages (prevents duplicate requests).
  final loadingMoreSections = <String>{}.obs;

  // ── Filter & Search Controls ─────────────────────────────────────────────

  /// Active category filter ('all' or a specific category key).
  final selectedCategory = 'all'.obs;

  /// Active sorting strategy for search results.
  final selectedSort = ProductSort.newest.obs;

  /// Direction toggle for price sorting (true = ascending, false = descending).
  final priceAscending = true.obs;

  // ── Flat Search State (Active while query text is entered) ────────────────

  /// Raw search results returned from the backend flat list endpoint.
  final products = <ProductModel>[].obs;

  /// Client-filtered search results (removes expired/out-of-stock items).
  final filteredProducts = <ProductModel>[].obs;

  /// True while fetching initial search results.
  final loading = false.obs;

  /// True if more search result pages exist on the backend.
  final hasMore = true.obs;

  /// Current page index for flat search pagination.
  final currentPage = 1.obs;

  /// True while fetching additional search pages.
  final loadingMore = false.obs;

  /// Error message string exposed to UI when requests fail.
  final fetchError = ''.obs;

  /// Standard pagination page size.
  static const int itemsPerPage = 20;

  /// Reactive search text value populated by external AppBar controllers.
  final searchText = ''.obs;

  /// Scroll controller attached to the vertical search/discovery list view.
  final scrollController = ScrollController();

  Timer? _debounce;
  int _requestId = 0;

  // ── Real-time Updates (Mercure) ──────────────────────────────────────────

  static const _mercure = MercureService();
  StreamSubscription? _mercureSub;
  Worker? _cityWorker;

  /// Tracked city slug to prevent unnecessary SSE connection rebuilds.
  String? _subscribedCitySlug;

  /// Isolated storage key generated per market instance.
  String get _cacheKey => 'product_sections_${market}_v1';

  // ── Lifecycle Hooks ───────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadCachedSections();
    fetchSections();
    scrollController.addListener(_onScroll);
    _watchCityForMercure();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _mercureSub?.cancel();
    _cityWorker?.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ── Real-Time SSE Management ─────────────────────────────────────────────

  /// Subscribes to Mercure notifications matching the customer's active delivery city.
  void _watchCityForMercure() {
    final addressCtrl = Get.find<AddressController>();
    _resubscribeForCity(addressCtrl.selectedAddress.value?.city);
    _cityWorker = ever(addressCtrl.selectedAddress, (address) {
      _resubscribeForCity(address?.city);
    });
  }

  /// Re-establishes the Mercure topic connection when the city changes.
  void _resubscribeForCity(String? city) {
    if (city == null || city.isEmpty) return;
    final slug = MercureService.citySlug(city);
    if (slug.isEmpty || slug == _subscribedCitySlug) return;

    _mercureSub?.cancel();
    _subscribedCitySlug = slug;

    _mercureSub = _mercure.subscribeToFoodOffers(
      // Food publishes new-listing events to the plain city topic (the
      // scheme FoodOfferController has always used) — only non-Food markets
      // get a market-prefixed slug to avoid colliding with Food's topic on
      // the same city. Subscribing Food to the prefixed variant here meant
      // this controller (the one CustomerFoodScreen actually renders) never
      // received the event a new business-partner listing publishes, so new
      // offers only ever showed up after a manual refetch.
      citySlug: market == 'food' ? slug : '$market-$slug',
      onOffer: (_) {
        AppLogger.info(
          _tag,
          'Mercure: new product available in $market — refreshing',
        );
        refreshForNewProduct();
      },
    );
  }

  // ── Local Storage & Caching ───────────────────────────────────────────────

  /// Restores cached category section rows from disk for immediate UI display.
  void _loadCachedSections() {
    final cached = DataCacheService.load(
      _cacheKey,
      (json) => (json as List)
          .map((e) => ProductSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (cached != null && cached.isNotEmpty) {
      sections.assignAll(cached);
      availableCategories.assignAll(cached.map((s) => s.category));
      isFromCache.value = true;
    }
  }

  /// Persists freshly fetched category sections to local disk storage.
  Future<void> _saveSectionsCache(List<ProductSectionModel> data) async {
    await DataCacheService.save(
      _cacheKey,
      data.map((s) => s.toJson()).toList(),
    );
  }

  // ── Sections & Category Pagination ──────────────────────────────────────

  /// Fetches all non-empty category section rows for [market] in a single request.
  ///
  /// Populates [sections] and [availableCategories]. Results are cached to local storage
  /// via [DataCacheService] for fast offline/instant initial renders.
  Future<void> fetchSections() async {
    sectionsLoading.value = true;
    fetchError.value = '';
    try {
      final result = await service.getSections(market: market);
      sections.assignAll(result);
      availableCategories.assignAll(result.map((s) => s.category));
      isFromCache.value = false;
      if (result.isNotEmpty) await _saveSectionsCache(result);
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchSections failed for market $market',
        error: e,
        stackTrace: st,
      );
      if (sections.isEmpty) fetchError.value = 'product_loadError'.tr;
    } finally {
      sectionsLoading.value = false;
    }
  }

  /// Swaps out the multi-section display to isolate a single [category] row.
  ///
  /// Triggered when the user selects a specific category pill. Keeps [availableCategories]
  /// intact so the filter bar remains fully populated.
  Future<void> fetchCategorySection(String category) async {
    sectionsLoading.value = true;
    fetchError.value = '';
    sections.clear();
    try {
      final result = await service.getSectionPage(
        market: market,
        category: category,
        page: 1,
      );
      sections.assignAll([result]);
      isFromCache.value = false;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchCategorySection($market, $category) failed',
        error: e,
        stackTrace: st,
      );
      fetchError.value = 'product_loadError'.tr;
    } finally {
      sectionsLoading.value = false;
    }
  }

  /// Appends the next page of items to a specific category section row.
  ///
  /// Called during rightward horizontal scrolling when `hasMore` is true and a `nextPage` exists.
  Future<void> loadSectionPage(String category) async {
    final idx = sections.indexWhere((s) => s.category == category);
    if (idx == -1) return;
    final section = sections[idx];
    if (!section.hasMore || loadingMoreSections.contains(category)) return;

    loadingMoreSections.add(category);
    try {
      final next = await service.getSectionPage(
        market: market,
        category: category,
        page: section.nextPage!,
        limit: section.limit,
      );
      sections[idx] = section.appendPage(
        more: next.items,
        hasMore: next.hasMore,
        nextPage: next.nextPage,
        limit: next.limit,
      );
      sections.refresh();
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'loadSectionPage($market, $category) failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      loadingMoreSections.remove(category);
    }
  }

  /// Handles category pill selection events.
  void onCategorySelected(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    if (category == 'all') {
      fetchSections();
    } else {
      fetchCategorySection(category);
    }
  }

  // ── Search & Flat Discovery ───────────────────────────────────────────────

  /// Debounces user keystrokes before dispatching a backend search query.
  void onSearchChanged(String value) {
    searchText.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      resetPagination();
      final int currentRequest = ++_requestId;
      fetchProducts(requestId: currentRequest);
    });
  }

  /// Fetches paginated flat search results across all categories.
  Future<void> fetchProducts({bool loadMore = false, int? requestId}) async {
    if (loadMore && (!hasMore.value || loadingMore.value)) return;

    if (loadMore) {
      loadingMore.value = true;
    } else {
      loading.value = true;
      resetPagination();
    }

    try {
      final sorting = _getSorting();
      final result = await service.getProducts(
        market: market,
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
        products.value = [...products, ...result];
      } else {
        products.assignAll(result);
      }

      _applyFilters();
      fetchError.value = '';
      hasMore.value = result.isNotEmpty && result.length >= itemsPerPage;
      if (result.isNotEmpty) currentPage.value++;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchProducts failed for market $market',
        error: e,
        stackTrace: st,
      );
      if (products.isEmpty) fetchError.value = 'product_loadError'.tr;
    } finally {
      loading.value = false;
      loadingMore.value = false;
    }
  }

  // ── Inventory Synchronization Methods ────────────────────────────────────

  /// Optimistically restores stock (units or weight) for matched line items across both
  /// horizontal section rows and search lists after an order cancellation.
  void restoreQuantities(List<OrderItemModel> items) {
    AppLogger.info(
      _tag,
      'restoreQuantities: crediting ${items.length} item(s) across sections and flat lists',
    );

    ProductModel apply(ProductModel product) {
      final match = items.firstWhereOrNull((i) => i.offerId == product.id);
      if (match == null) return product;
      return product.isWeightBased
          ? product.copyWith(
              weightAvailableKg:
                  (product.weightAvailableKg ?? 0) + (match.weightTotalKg ?? 0),
            )
          : product.copyWith(
              quantityAvailable:
                  (product.quantityAvailable ?? 0) + match.quantity,
            );
    }

    var sectionsMatched = 0;
    for (int si = 0; si < sections.length; si++) {
      final section = sections[si];
      bool changed = false;
      final updatedItems = section.items.map((prod) {
        final updated = apply(prod);
        if (!identical(updated, prod)) changed = true;
        return updated;
      }).toList();

      if (changed) {
        sectionsMatched++;
        sections[si] = ProductSectionModel(
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

    var productsMatched = 0;
    for (final item in items) {
      final idx = products.indexWhere((p) => p.id == item.offerId);
      if (idx != -1) {
        productsMatched++;
        products[idx] = apply(products[idx]);
      }
    }
    _applyFilters();

    AppLogger.info(
      _tag,
      'restoreQuantities ($market): matched in $sectionsMatched section row(s), '
      '$productsMatched flat product row(s)',
    );
  }

  /// Immediately decrements available stock for [productId] across all cached lists
  /// upon successful order checkout to prevent showing stale inventory.
  void reduceQuantity(
    int productId, {
    required int quantity,
    double? weightKg,
  }) {
    ProductModel apply(ProductModel product) {
      final qty = product.quantityAvailable;
      final weight = product.weightAvailableKg;
      return product.copyWith(
        quantityAvailable: qty == null ? null : _clampMin0(qty - quantity),
        weightAvailableKg: (weight == null || weightKg == null)
            ? weight
            : _clampMin0Double(weight - weightKg),
      );
    }

    for (int si = 0; si < sections.length; si++) {
      final section = sections[si];
      var changed = false;
      final updatedItems = section.items.map((prod) {
        if (prod.id != productId) return prod;
        changed = true;
        return apply(prod);
      }).toList();

      if (changed) {
        sections[si] = ProductSectionModel(
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

    final idx = products.indexWhere((p) => p.id == productId);
    if (idx != -1) products[idx] = apply(products[idx]);
    _applyFilters();
  }

  int _clampMin0(int v) => v < 0 ? 0 : v;
  double _clampMin0Double(double v) => v < 0 ? 0 : v;

  /// Refreshes active UI view upon receipt of background Mercure notifications.
  void refreshForNewProduct() {
    if (searchText.value.trim().isNotEmpty) return;
    if (selectedCategory.value == 'all') {
      fetchSections();
    } else {
      fetchCategorySection(selectedCategory.value);
    }
  }

  // ── Helper & Utility Methods ──────────────────────────────────────────────

  /// Resets search pagination state back to initial page 1.
  void resetPagination() {
    currentPage.value = 1;
    hasMore.value = true;
    products.clear();
    filteredProducts.clear();
  }

  /// Filters out inactive, expired, or out-of-stock items locally.
  void _applyFilters() {
    final now = DateTime.now();
    List<ProductModel> list = List.from(products);
    list = list
        .where((p) => p.endTime == null || !now.isAfter(p.endTime!))
        .toList();
    list = list
        .where(
          (p) => p.isWeightBased
              ? (p.weightAvailableKg ?? 0) > 0
              : (p.quantityAvailable ?? 0) > 0,
        )
        .toList();
    filteredProducts.assignAll(list);
  }

  /// Listener callback triggering pagination loading when scrolling near list bottom.
  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (loadingMore.value || !hasMore.value) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      fetchProducts(loadMore: true);
    }
  }

  /// Translates UI sort enums to backend API field names and directions.
  (String?, String?) _getSorting() {
    switch (selectedSort.value) {
      case ProductSort.newest:
        return ('createdAt', 'desc');
      case ProductSort.price:
        return ('salePrice', priceAscending.value ? 'asc' : 'desc');
      case ProductSort.popular:
        return ('quantityAvailable', 'desc');
    }
  }
}
