import 'dart:async';

import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:notification/notification.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Manages the set of offers the user has marked as favorite.
///
/// State is exposed reactively so the UI can rebuild via `Obx`:
/// - [favoriteIds]   : ids currently marked favorite
/// - [isLoading]     : true while the initial list is being fetched
/// - [errorMessage]  : last load error (null when load succeeded)
class FavoritesOfferController extends GetxController {
  FavoritesOfferController(this._service);

  final FavoriteOfferService _service;

  // --- Reactive state -------------------------------------------------------

  /// Ids of offers marked as favorite — O(1) lookups for the heart button.
  final favoriteIds = <int>{}.obs;

  /// Full offer models for the favorites screen — populated by [loadFavorites]
  /// and kept in sync by [toggleFavorite].
  final favoriteOffers = <ProductModel>[].obs;

  /// True while [loadFavorites] is running. Use it to show a spinner.
  final isLoading = false.obs;

  /// Non-null when the last load failed. Lets the UI show a retry view.
  final errorMessage = RxnString();

  /// True while showing cached favorites from the previous session.
  final isFromCache = false.obs;

  /// Ids that just flipped from sold-out to available while this screen was
  /// open (live Mercure update, not a fresh load) — used to show a brief
  /// "back in stock" highlight on the card before it settles back to the
  /// normal available look. See [_onStockEvent].
  final justRestockedIds = <int>{}.obs;

  static const _cacheKey = 'customer_favorites';
  static const _restockHighlightDuration = Duration(seconds: 5);

  final MercureService _mercureService = const MercureService();

  /// One live SSE subscription per currently sold-out favorite — these are
  /// exactly the offers the user is "waiting on", so this is the minimal set
  /// that needs watching for a restock. Offers that are already available
  /// don't need a live connection: nothing the user is waiting for can
  /// happen to them here. Keyed by offer id so re-syncing is idempotent.
  final Map<int, StreamSubscription> _stockSubs = {};

  /// Convenience getter for badges / counters.
  int get favoritesCount => favoriteIds.length;

  // ── Filter / search state ─────────────────────────────────────────────────
  // NOTE: no TextEditingController here on purpose — this controller is
  // `fenix: true` and can be disposed/recreated independently of
  // MainNavigationScreen's AppBar, which is where the search field actually
  // lives and stays mounted across every tab switch. MainNavigationScreen
  // owns the TextEditingController and passes it into FavoritesScreen; only
  // the reactive text value lives here. (Previously owning it here caused
  // "Once you have called dispose()... it can no longer be used".)
  final searchQuery = ''.obs;
  final sortOrder = FavoritesSort.alphabetical.obs;
  final categoryFilter = 'all'.obs;

  /// Returns [rawFavorites] filtered and sorted by the current reactive state.
  /// Call inside [Obx] so the list rebuilds when any filter changes.
  List<ProductModel> filteredFavorites(List<ProductModel> rawFavorites) {
    var result = rawFavorites.toList();

    // Search by title or business name.
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((o) {
        return o.title.toLowerCase().contains(q) ||
            (o.businessPartner?.businessName.toLowerCase().contains(q) ??
                false);
      }).toList();
    }

    // Category filter.
    if (categoryFilter.value != 'all') {
      result = result.where((o) => o.category == categoryFilter.value).toList();
    }

    // Sort.
    switch (sortOrder.value) {
      case FavoritesSort.alphabetical:
        result.sort((a, b) => a.title.compareTo(b.title));
      case FavoritesSort.priceLowHigh:
        result.sort(
          (a, b) => (double.tryParse(a.price ?? '') ?? 0).compareTo(
            double.tryParse(b.price ?? '') ?? 0,
          ),
        );
      case FavoritesSort.priceHighLow:
        result.sort(
          (a, b) => (double.tryParse(b.price ?? '') ?? 0).compareTo(
            double.tryParse(a.price ?? '') ?? 0,
          ),
        );
    }

    return result;
  }

  // --- Lifecycle ------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadCachedFavorites();
    loadFavorites();
  }

  @override
  void onClose() {
    for (final sub in _stockSubs.values) {
      sub.cancel();
    }
    _stockSubs.clear();
    super.onClose();
  }

  // --- Public API -----------------------------------------------------------

  /// Returns whether [offerId] is currently a favorite.
  bool isFavorite(int offerId) => favoriteIds.contains(offerId);

  /// Shows the last-known favorites list immediately (if any and not stale)
  /// while [loadFavorites] fetches the fresh one in the background.
  void _loadCachedFavorites() {
    final cached = DataCacheService.load(
      _cacheKey,
      (json) => (json as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (cached != null && cached.isNotEmpty) {
      favoriteOffers.value = cached;
      favoriteIds
        ..clear()
        ..addAll(cached.map((o) => o.id));
      isFromCache.value = true;
      _syncStockSubscriptions();
    }
  }

  /// Fetches the favorite offers from the backend and replaces local state.
  ///
  /// On failure, existing favorites are kept untouched and [errorMessage]
  /// is set so the UI can react.
  Future<void> loadFavorites() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final favorites = await _service.getFavorites();
      // Cancelled, deleted, expired, and hidden offers are silently dropped —
      // there's nothing the user can act on there. Sold-out offers are kept
      // (unlike before): the whole point of favoriting is to be alerted when
      // a sold-out item comes back, so hiding it here would silently break
      // that promise. See FavoritesScreen/OfferCard for the "we'll notify
      // you" treatment shown for these.
      final live = favorites
          .where(
            (o) =>
                o.status == 'active' ||
                o.status == 'scheduled' ||
                o.status == 'sold_out',
          )
          .toList();
      favoriteOffers.value = live;
      favoriteIds
        ..clear()
        ..addAll(live.map((o) => o.id));
      isFromCache.value = false;
      await DataCacheService.save(
        _cacheKey,
        live.map((o) => o.toJson()).toList(),
      );
      _syncStockSubscriptions();
    } catch (e, stackTrace) {
      errorMessage.value = 'Could not load favorites';
      _logError('loadFavorites', e, stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  /// Adds or removes [offer] from favorites.
  ///
  /// Optimistic update: the UI changes immediately, then persisted to the
  /// backend. Rolls back if the call fails.
  Future<void> toggleFavorite(int offerId, {ProductModel? offer}) async {
    final wasFavorite = favoriteIds.contains(offerId);

    // Removing an already-favorited sold-out item is still allowed (lets the
    // user clean up their list) — only adding a new sold-out favorite is
    // blocked, since there's nothing left to come back and order.
    if (!wasFavorite && offer?.isSoldOut == true) {
      AppSnackbar.error('', CustomerFavoritesStrings.cannotAddSoldOut);
      return;
    }

    // 1. Optimistic update.
    if (wasFavorite) {
      favoriteIds.remove(offerId);
      favoriteOffers.removeWhere((o) => o.id == offerId);
    } else {
      favoriteIds.add(offerId);
      if (offer != null) favoriteOffers.add(offer);
    }
    _syncStockSubscriptions();

    // 2. Persist.
    try {
      if (wasFavorite) {
        await _service.removeFavorite(offerId);
      } else {
        await _service.addFavorite(offerId);
      }
    } catch (e, stackTrace) {
      // 3. Rollback.
      if (wasFavorite) {
        favoriteIds.add(offerId);
        if (offer != null) favoriteOffers.add(offer);
      } else {
        favoriteIds.remove(offerId);
        favoriteOffers.removeWhere((o) => o.id == offerId);
      }
      _syncStockSubscriptions();
      _logError('toggleFavorite', e, stackTrace);
      // Log the detailed error so it's visible in debug output.
      AppLogger.error('FavoritesOfferController', 'toggleFavorite detail: $e');
      AppSnackbar.error(ErrorStrings.title, CustomerFavoritesStrings.toggleError);
    }
  }

  // --- Local stock sync (this user's own order actions) ----------------------

  /// Decrements available stock for [offerId] in the favorites list right
  /// after the current user places an order for it — mirrors
  /// `FoodOfferController.reduceQuantity`, which already does this for the
  /// Home screen. Without this, a favorited item you just bought out kept
  /// showing its stale pre-order stock here until the next full
  /// [loadFavorites] (e.g. app restart or re-login), even though Home
  /// already showed it correctly as sold out — the exact "opens fine, can't
  /// reserve, only fixes itself after logging back in" bug this closes.
  /// Also re-syncs the live restock watch, since a self-triggered sold-out
  /// favorite needs the same "notify me" subscription as one sold out by
  /// someone else.
  void reduceQuantity(int offerId, {required int quantity, double? weightKg}) {
    final index = favoriteOffers.indexWhere((o) => o.id == offerId);
    if (index == -1) return;

    final offer = favoriteOffers[index];
    final qty = offer.quantityAvailable;
    final weight = offer.weightAvailableKg;
    favoriteOffers[index] = offer.copyWith(
      quantityAvailable: qty == null ? null : _clampMin0(qty - quantity),
      weightAvailableKg: (weight == null || weightKg == null)
          ? weight
          : _clampMin0Double(weight - weightKg),
    );
    _syncStockSubscriptions();
    DataCacheService.save(
      _cacheKey,
      favoriteOffers.map((o) => o.toJson()).toList(),
    );
  }

  /// Credits back the stock this same user's own cancelled/deleted order had
  /// reserved, for whichever of [items] are currently favorited — mirrors
  /// `FoodOfferController.restoreQuantities`. Also re-syncs the live restock
  /// watch: crossing back to available here drops the now-unnecessary
  /// subscription, same as a backend-driven restock does in [_onStockEvent].
  void restoreQuantities(List<OrderItemModel> items) {
    var changed = false;
    for (final item in items) {
      final index = favoriteOffers.indexWhere((o) => o.id == item.foodOffer.id);
      if (index == -1) continue;
      changed = true;
      final offer = favoriteOffers[index];
      favoriteOffers[index] = offer.isWeightBased
          ? offer.copyWith(
              weightAvailableKg:
                  (offer.weightAvailableKg ?? 0) + (item.weightTotalKg ?? 0),
            )
          : offer.copyWith(
              quantityAvailable: (offer.quantityAvailable ?? 0) + item.quantity,
            );
    }
    if (!changed) return;
    _syncStockSubscriptions();
    DataCacheService.save(
      _cacheKey,
      favoriteOffers.map((o) => o.toJson()).toList(),
    );
  }

  int _clampMin0(int v) => v < 0 ? 0 : v;
  double _clampMin0Double(double v) => v < 0 ? 0 : v;

  // --- Live restock alerts ----------------------------------------------------

  /// Opens/closes SSE subscriptions so exactly the currently sold-out
  /// favorites have a live connection watching their stock — called after
  /// every mutation of [favoriteOffers] (initial load, cache restore, toggle).
  void _syncStockSubscriptions() {
    final waiting = favoriteOffers
        .where((o) => o.isSoldOut)
        .map((o) => o.id)
        .toSet();

    for (final id in _stockSubs.keys.toList()) {
      if (!waiting.contains(id)) {
        _stockSubs.remove(id)?.cancel();
      }
    }
    for (final id in waiting) {
      if (_stockSubs.containsKey(id)) continue;
      _stockSubs[id] = _mercureService.subscribeToOfferStock(
        offerId: id,
        onStock: (event) => _onStockEvent(id, event),
      );
    }
  }

  /// Applies a live stock update to the matching favorite. When it flips the
  /// offer from sold-out to available, flags it in [justRestockedIds] for a
  /// brief celebratory highlight and shows a toast — this is the "TGTG
  /// notify me" moment landing while the user has the screen open, as
  /// opposed to the FCM push handling the case where they don't.
  void _onStockEvent(int offerId, OfferStockMercureEvent event) {
    final index = favoriteOffers.indexWhere((o) => o.id == offerId);
    if (index == -1) return;

    final previous = favoriteOffers[index];
    final wasSoldOut = previous.isSoldOut;

    final updated = previous.copyWith(
      status: event.status,
      quantityAvailable: event.quantityAvailable,
      weightAvailableKg: event.weightAvailableKg,
    );
    favoriteOffers[index] = updated;
    DataCacheService.save(
      _cacheKey,
      favoriteOffers.map((o) => o.toJson()).toList(),
    );

    if (wasSoldOut && !updated.isSoldOut) {
      justRestockedIds.add(offerId);
      AppSnackbar.show(
        title: '',
        message: CustomerFavoritesStrings.justBackInStock(updated.title),
        icon: Icons.celebration_rounded,
        iconColor: AppColors.success,
      );
      Future.delayed(_restockHighlightDuration, () {
        justRestockedIds.remove(offerId);
      });
    }

    // The offer is either no longer sold out (no need to keep watching it,
    // it settled into justRestockedIds' temporary highlight instead) or it's
    // still sold out (subscription should stay open) — either way the set of
    // ids needing a live connection may have changed.
    _syncStockSubscriptions();
  }

  // --- Helpers --------------------------------------------------------------

  void _logError(String where, Object error, StackTrace stackTrace) {
    AppLogger.error(
      'FavoritesOfferController',
      where,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
