// lib/controllers/business_offer_controller.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:core/core.dart';

/// Owns the partner "add a surplus bag to the menu" flow.
///
/// All the FORM STATE lives here (text controllers, category, quantity, pickup
/// window) so the screen can be a plain StatelessWidget — the controller is the
/// single source of truth and Obx rebuilds the reactive bits.
class BusinessOfferController extends GetxController {
  BusinessOfferController(this._service);

  final FoodOfferService _service;
  static const _tag = 'BusinessOfferController';

  // ───────────────────────── FORM STATE ─────────────────────────

  final formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final originalCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  // Weight-based fields
  final isWeightBased = false.obs;
  final weightKgCtrl = TextEditingController(); // kg available
  final pricePerKgCtrl = TextEditingController(); // price per kg
  final minOrderKgCtrl = TextEditingController(); // min order (optional)

  static const categories = <String>[
    'fast_food',
    'pizza',
    'bakery',
    'restaurant',
    'supermarket',
    'cafe',
    'meals',
    'bread_pastries',
    'fruits_vegetables',
    'groceries',
    'hot_drinks',
    'cheese_dairy',
    'butcher',
    'fish',
    'deli_catering',
    'flowers',
    'salads',
  ];

  final category = 'fast_food'.obs;
  final quantity = 1.obs;
  final pickupStart = Rxn<DateTime>();
  final pickupEnd = Rxn<DateTime>();

  // ───────────────────────── SUBMIT STATE ─────────────────────────

  final isSaving = false.obs;
  final errorText = ''.obs; // '' = no error

  // Used by BusinessOfferEditScreen after an updateOffer failure.
  String updateErrorText = '';

  // ───────────────────────── LIST STATE ─────────────────────────

  /// The partner's own offers (their menu) — raw, unfiltered list from the API.
  final myOffers = <FoodOfferModel>[].obs;
  final isLoadingOffers = false.obs;
  final listError = ''.obs; // '' = no error

  static const int _itemsPerPage = 20;
  final hasMoreOffers = true.obs;
  final isLoadingMoreOffers = false.obs;
  int _offersPage = 1;

  bool _offersLoadedOnce = false;
  int _loadedForPartnerId = 0;

  /// True while showing cached offers from the previous session.
  final isFromCache = false.obs;

  // ───────────────────────── MENU FILTER STATE ─────────────────────────

  /// Search query typed in [BusinessMenuScreen].
  final offerSearch = ''.obs;

  /// Sort direction for [BusinessMenuScreen].
  final offerSort = OfferSortOrder.newest.obs;

  /// Status filter for [BusinessMenuScreen].
  final offerStatusFilter = OfferStatusFilter.all.obs;

  /// Returns [myOffers] with status filter, search, and sort applied.
  ///
  /// Because it reads reactive values, any [Obx] that calls this will
  /// automatically rebuild when [offerSearch], [offerSort],
  /// [offerStatusFilter], or [myOffers] change.
  List<FoodOfferModel> get filteredOffers {
    var list = myOffers.toList();

    // 1. Status filter — skip when set to "all".
    final statusVal = offerStatusFilter.value.apiValue;
    if (statusVal != null) {
      list = list.where((o) => o.status == statusVal).toList();
    }

    // 2. Text search — matches title or category.
    final q = offerSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (o) =>
                o.title.toLowerCase().contains(q) ||
                o.category.toLowerCase().contains(q),
          )
          .toList();
    }

    // 3. Sort by pickup start time.
    list.sort(
      (a, b) => offerSort.value == OfferSortOrder.newest
          ? b.startTime.compareTo(a.startTime)
          : a.startTime.compareTo(b.startTime),
    );

    return list;
  }

  /// Resets all menu filters to their defaults.
  void clearOfferFilters() {
    offerSearch.value = '';
    offerSort.value = OfferSortOrder.newest;
    offerStatusFilter.value = OfferStatusFilter.all;
  }

  /// Loads the offers ONCE (first time the Menu tab is shown). Lets the screen
  /// stay stateless — call this from build via a post-frame callback. Manual
  /// refresh / after-create still call [fetchMyOffers] directly.
  Future<void> ensureOffersLoaded(int businessPartnerId) async {
    if (businessPartnerId == 0) return;
    if (isLoadingOffers.value) return;
    // Skip only if already loaded for this exact partner.
    // If the logged-in partner changed (different user), reload.
    if (_offersLoadedOnce && _loadedForPartnerId == businessPartnerId) return;
    _offersLoadedOnce = true;
    _loadedForPartnerId = businessPartnerId;
    _loadCachedOffers(businessPartnerId);
    await fetchMyOffers(businessPartnerId);
  }

  String _cacheKey(int businessPartnerId) =>
      'business_offers_$businessPartnerId';

  /// Shows the last-known menu immediately (if any and not stale) while
  /// [fetchMyOffers] fetches the fresh page in the background.
  void _loadCachedOffers(int businessPartnerId) {
    final cached = DataCacheService.load(
      _cacheKey(businessPartnerId),
      (json) => (json as List)
          .map((e) => FoodOfferModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (cached != null && cached.isNotEmpty) {
      myOffers.assignAll(cached);
      isFromCache.value = true;
    }
  }

  /// Loads this partner's offers for the Menu page (first page).
  Future<void> fetchMyOffers(int businessPartnerId) async {
    if (businessPartnerId == 0) return;
    isLoadingOffers.value = true;
    listError.value = '';
    _offersPage = 1;
    hasMoreOffers.value = true;
    try {
      final result = await _service.getBusinessOffers(
        businessPartnerId,
        page: _offersPage,
        itemsPerPage: _itemsPerPage,
      );
      myOffers.assignAll(result);
      hasMoreOffers.value = result.length >= _itemsPerPage;
      if (result.isNotEmpty) _offersPage++;
      isFromCache.value = false;
      await DataCacheService.save(
        _cacheKey(businessPartnerId),
        result.map((o) => o.toJson()).toList(),
      );
    } catch (e) {
      listError.value = 'Could not load your offers.';
    } finally {
      isLoadingOffers.value = false;
    }
  }

  /// Appends the next page of offers as the partner scrolls the menu list.
  Future<void> loadMoreOffers(int businessPartnerId) async {
    if (businessPartnerId == 0) return;
    if (isLoadingMoreOffers.value || !hasMoreOffers.value) return;
    isLoadingMoreOffers.value = true;
    try {
      final result = await _service.getBusinessOffers(
        businessPartnerId,
        page: _offersPage,
        itemsPerPage: _itemsPerPage,
      );
      myOffers.addAll(result);
      hasMoreOffers.value = result.length >= _itemsPerPage;
      if (result.isNotEmpty) _offersPage++;
    } catch (e) {
      // Silent failure — the partner can retry by scrolling again.
    } finally {
      isLoadingMoreOffers.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    originalCtrl.dispose();
    priceCtrl.dispose();
    weightKgCtrl.dispose();
    pricePerKgCtrl.dispose();
    minOrderKgCtrl.dispose();
    super.onClose();
  }

  // ───────────────────────── MUTATORS ─────────────────────────

  void setCategory(String c) => category.value = c;
  void increaseQty() => quantity.value++;
  void decreaseQty() {
    if (quantity.value > 1) quantity.value--;
  }

  /// Stores a chosen pickup time. Setting the start also nudges the end to stay
  /// after it.
  void setPickup({required bool isStart, required DateTime dt}) {
    if (isStart) {
      pickupStart.value = dt;
      if (pickupEnd.value != null && pickupEnd.value!.isBefore(dt)) {
        pickupEnd.value = dt.add(const Duration(hours: 1));
      }
    } else {
      pickupEnd.value = dt;
    }
  }

  /// Clears everything for a fresh form (call after a successful publish, or
  /// before navigating in if you want a clean slate each time).
  void resetForm() {
    nameCtrl.clear();
    descCtrl.clear();
    originalCtrl.clear();
    priceCtrl.clear();
    weightKgCtrl.clear();
    pricePerKgCtrl.clear();
    minOrderKgCtrl.clear();
    isWeightBased.value = false;
    category.value = categories.first;
    quantity.value = 1;
    pickupStart.value = null;
    pickupEnd.value = null;
    errorText.value = '';
  }

  // ───────────────────────── SUBMIT ─────────────────────────

  /// PATCHes an existing offer. Returns true on success.
  /// On failure [updateErrorText] holds a human-readable message.
  Future<bool> updateOffer(int offerId, Map<String, dynamic> body) async {
    updateErrorText = '';
    try {
      final updated = await _service.updateOffer(offerId, body);
      // Swap the old entry in myOffers so the list rebuilds immediately.
      // Override status with what we sent: the backend's getStatus() may
      // compute a different value (e.g. 'inactive' → 'active') that doesn't
      // reflect the partner's intent.
      final idx = myOffers.indexWhere((o) => o.id == offerId);
      if (idx != -1) {
        final sentStatus = body['status'] as String?;
        myOffers[idx] = sentStatus != null
            ? updated.copyWith(status: sentStatus)
            : updated;
      }
      return true;
    } on DioException catch (e) {
      final d = e.response?.data;
      updateErrorText = (d is Map && d['hydra:description'] != null)
          ? d['hydra:description'].toString()
          : 'Could not update (${e.response?.statusCode ?? 'network error'}).';
      return false;
    } catch (e) {
      updateErrorText = 'Unexpected error: $e';
      return false;
    }
  }

  /// Permanently deletes an offer and removes it from the local list.
  Future<bool> deleteOffer(int offerId) async {
    updateErrorText = '';
    try {
      await _service.deleteOffer(offerId);
      myOffers.removeWhere((o) => o.id == offerId);
      return true;
    } on DioException catch (e) {
      updateErrorText =
          'Could not delete (${e.response?.statusCode ?? 'network error'}).';
      return false;
    } catch (e) {
      updateErrorText = 'Unexpected error: $e';
      return false;
    }
  }

  /// Restores available quantity/weight on [myOffers] after one of this
  /// business's orders is cancelled or rejected, so the Menu tab's stock
  /// pills reflect the freed-up inventory immediately instead of waiting on
  /// the next manual refresh or a live Mercure event (which only fires if
  /// the backend echoes order events back to the business that owns them —
  /// this makes the partner's own cancel/reject action correct regardless).
  /// Mirrors [FoodOfferController.restoreQuantities] (customer side).
  void restoreQuantities(List<OrderItemModel> items) {
    AppLogger.info(
      _tag,
      'restoreQuantities: crediting ${items.length} item(s) for offer id(s) '
      '${items.map((i) => i.foodOffer.id).toList()} across '
      '${myOffers.length} myOffers row(s)',
    );
    var matched = 0;
    for (final item in items) {
      final idx = myOffers.indexWhere((o) => o.id == item.foodOffer.id);
      if (idx == -1) continue;
      matched++;
      final offer = myOffers[idx];
      myOffers[idx] = offer.isWeightBased
          ? offer.copyWith(
              weightAvailableKg:
                  (offer.weightAvailableKg ?? 0) + (item.weightTotalKg ?? 0),
            )
          : offer.copyWith(
              quantityAvailable: (offer.quantityAvailable ?? 0) + item.quantity,
            );
    }
    AppLogger.info(
      _tag,
      'restoreQuantities: matched $matched/${items.length} item(s) in '
      "myOffers — if 0, the offer(s) aren't currently loaded in this "
      'controller (e.g. Menu tab never opened this session)',
    );
  }

  /// Validates the form and builds a local [FoodOfferModel] without posting.
  /// Returns null and sets [errorText] if validation fails.
  FoodOfferModel? buildDraft() {
    if (!(formKey.currentState?.validate() ?? false)) return null;

    if (pickupStart.value == null || pickupEnd.value == null) {
      errorText.value = 'Please set a pickup window.';
      return null;
    }
    if (!pickupEnd.value!.isAfter(pickupStart.value!)) {
      errorText.value = 'Pickup end must be after the start.';
      return null;
    }

    errorText.value = '';

    if (isWeightBased.value) {
      final perKg = double.parse(pricePerKgCtrl.text.replaceAll(',', '.'));
      final weightKg = double.parse(weightKgCtrl.text.replaceAll(',', '.'));
      final minKgText = minOrderKgCtrl.text.trim();
      final minKg = minKgText.isEmpty
          ? null
          : double.tryParse(minKgText.replaceAll(',', '.'));
      final orig = originalCtrl.text.trim();

      return FoodOfferModel.draftWeight(
        title: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        category: category.value,
        originalPrice: orig.isEmpty
            ? null
            : double.parse(orig.replaceAll(',', '.')).toStringAsFixed(2),
        pricePerKg: perKg,
        weightAvailableKg: weightKg,
        minOrderKg: minKg,
        startTime: pickupStart.value!,
        endTime: pickupEnd.value!,
      );
    } else {
      final original = double.parse(originalCtrl.text.replaceAll(',', '.'));
      final price = double.parse(priceCtrl.text.replaceAll(',', '.'));

      return FoodOfferModel.draft(
        title: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        category: category.value,
        originalPrice: original.toStringAsFixed(2),
        price: price.toStringAsFixed(2),
        quantity: quantity.value,
        startTime: pickupStart.value!,
        endTime: pickupEnd.value!,
      );
    }
  }

  /// Validates form, builds a draft, and POSTs it. Returns created model.
  /// On failure [errorText] holds a message.
  Future<FoodOfferModel?> submit(int businessPartnerId) async {
    final draft = buildDraft();
    if (draft == null) return null;
    return submitDraft(draft, businessPartnerId);
  }

  /// POSTs a pre-built [draft] without re-running form validation.
  /// Use this when the form is offscreen (e.g. called from the preview screen).
  Future<FoodOfferModel?> submitDraft(
    FoodOfferModel draft,
    int businessPartnerId,
  ) async {
    isSaving.value = true;
    errorText.value = '';

    try {
      final body = draft.toPostJson(businessPartnerId);
      debugPrint('[submitDraft] POST body: $body');
      final created = await _service.createOffer(body);
      resetForm();
      return created;
    } on DioException catch (e) {
      final d = e.response?.data;
      debugPrint('[submitDraft] status=${e.response?.statusCode} data=$d');
      debugPrint('[submitDraft] headers=${e.response?.headers}');
      errorText.value = (d is Map && d['hydra:description'] != null)
          ? d['hydra:description'].toString()
          : 'Could not save (${e.response?.statusCode ?? 'network error'}).';
      return null;
    } catch (e) {
      errorText.value = 'Unexpected error: $e';
      return null;
    } finally {
      isSaving.value = false;
    }
  }
}
