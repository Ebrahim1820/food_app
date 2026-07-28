import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:core/core.dart';

/// Owns the business partner "publish a listing" flow for the generic
/// Product catalog, scoped to a single [market] — the market-agnostic
/// counterpart to `BusinessOfferController`.
///
/// All form state (including the picked photo, kept here as an [Rxn] rather
/// than local State so the create screen can stay a [StatelessWidget]) lives
/// here — the screen just renders it via `Obx`.
class BusinessProductController extends GetxController {
  BusinessProductController(this._service, {required this.market});

  final ProductService _service;
  final String market;
  static const _tag = 'BusinessProductController';

  // ───────────────────────── FORM STATE ─────────────────────────

  final formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final originalCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  final isWeightBased = false.obs;
  final weightKgCtrl = TextEditingController();
  final pricePerKgCtrl = TextEditingController();
  final minOrderKgCtrl = TextEditingController();

  final category = Rxn<String>();
  final quantity = 1.obs;

  /// The photo picked for the listing, kept reactive here (not in the
  /// screen's State) so the create screen can stay a StatelessWidget.
  final pendingImage = Rxn<XFile>();

  // ───────────────────────── SUBMIT STATE ─────────────────────────

  final isSaving = false.obs;
  final errorText = ''.obs;
  String updateErrorText = '';

  // ───────────────────────── LIST STATE ─────────────────────────

  final myProducts = <ProductModel>[].obs;
  final isLoadingProducts = false.obs;
  final listError = ''.obs;

  static const int _itemsPerPage = 20;
  final hasMoreProducts = true.obs;
  final isLoadingMoreProducts = false.obs;
  int _productsPage = 1;

  bool _productsLoadedOnce = false;
  int _loadedForPartnerId = 0;
  final isFromCache = false.obs;

  /// Owned here (not in a screen's State) so `MyProductsScreen` can stay a
  /// StatelessWidget — see the class doc comment.
  final scrollController = ScrollController();
  int _cachedPartnerId = 0;
  bool _scrollListenerAttached = false;

  void attachScrollPagination() {
    if (_scrollListenerAttached) return;
    _scrollListenerAttached = true;
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        loadMoreProducts(_cachedPartnerId);
      }
    });
  }

  final productSearch = ''.obs;
  final productSort = OfferSortOrder.newest.obs;
  final productStatusFilter = OfferStatusFilter.all.obs;

  List<ProductModel> get filteredProducts {
    var list = myProducts.toList();

    final statusVal = productStatusFilter.value.apiValue;
    if (statusVal != null) {
      list = list.where((p) => p.status == statusVal).toList();
    }

    final q = productSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();
    }

    list.sort(
      (a, b) => productSort.value == OfferSortOrder.newest
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );

    return list;
  }

  void clearProductFilters() {
    productSearch.value = '';
    productSort.value = OfferSortOrder.newest;
    productStatusFilter.value = OfferStatusFilter.all;
  }

  Future<void> ensureProductsLoaded(int businessPartnerId) async {
    _cachedPartnerId = businessPartnerId;
    if (businessPartnerId == 0) return;
    if (isLoadingProducts.value) return;
    if (_productsLoadedOnce && _loadedForPartnerId == businessPartnerId) return;
    _productsLoadedOnce = true;
    _loadedForPartnerId = businessPartnerId;
    _loadCachedProducts(businessPartnerId);
    await fetchMyProducts(businessPartnerId);
  }

  String _cacheKey(int businessPartnerId) =>
      'business_products_${market}_$businessPartnerId';

  void _loadCachedProducts(int businessPartnerId) {
    final cached = DataCacheService.load(
      _cacheKey(businessPartnerId),
      (json) => (json as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (cached != null && cached.isNotEmpty) {
      myProducts.assignAll(cached);
      isFromCache.value = true;
    }
  }

  Future<void> fetchMyProducts(int businessPartnerId) async {
    if (businessPartnerId == 0) return;
    isLoadingProducts.value = true;
    listError.value = '';
    _productsPage = 1;
    hasMoreProducts.value = true;
    try {
      final result = await _service.getBusinessProducts(
        businessPartnerId,
        page: _productsPage,
        itemsPerPage: _itemsPerPage,
      );
      myProducts.assignAll(result);
      hasMoreProducts.value = result.length >= _itemsPerPage;
      if (result.isNotEmpty) _productsPage++;
      isFromCache.value = false;
      await DataCacheService.save(
        _cacheKey(businessPartnerId),
        result.map((p) => p.toJson()).toList(),
      );
    } catch (e) {
      AppLogger.error(_tag, 'fetchMyProducts failed', error: e);
      listError.value = 'productBiz_loadError'.tr;
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> loadMoreProducts(int businessPartnerId) async {
    if (businessPartnerId == 0) return;
    if (isLoadingMoreProducts.value || !hasMoreProducts.value) return;
    isLoadingMoreProducts.value = true;
    try {
      final result = await _service.getBusinessProducts(
        businessPartnerId,
        page: _productsPage,
        itemsPerPage: _itemsPerPage,
      );
      myProducts.addAll(result);
      hasMoreProducts.value = result.length >= _itemsPerPage;
      if (result.isNotEmpty) _productsPage++;
    } catch (_) {
      // Silent failure — the partner can retry by scrolling again.
    } finally {
      isLoadingMoreProducts.value = false;
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
    scrollController.dispose();
    super.onClose();
  }

  // ───────────────────────── MUTATORS ─────────────────────────

  void setCategory(String c) => category.value = c;
  void increaseQty() => quantity.value++;
  void decreaseQty() {
    if (quantity.value > 1) quantity.value--;
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) pendingImage.value = picked;
    } catch (e) {
      AppLogger.error(_tag, 'pickImage failed', error: e);
    }
  }

  void clearImage() => pendingImage.value = null;

  void resetForm() {
    nameCtrl.clear();
    descCtrl.clear();
    originalCtrl.clear();
    priceCtrl.clear();
    weightKgCtrl.clear();
    pricePerKgCtrl.clear();
    minOrderKgCtrl.clear();
    isWeightBased.value = false;
    category.value = null;
    quantity.value = 1;
    pendingImage.value = null;
    errorText.value = '';
  }

  // ───────────────────────── SUBMIT ─────────────────────────

  Future<bool> updateProduct(int productId, Map<String, dynamic> body) async {
    updateErrorText = '';
    try {
      final updated = await _service.updateProduct(productId, body);
      final idx = myProducts.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        final sentStatus = body['status'] as String?;
        myProducts[idx] = sentStatus != null
            ? updated.copyWith(status: sentStatus)
            : updated;
      }
      return true;
    } on DioException catch (e) {
      final d = e.response?.data;
      updateErrorText = (d is Map && d['hydra:description'] != null)
          ? d['hydra:description'].toString()
          : 'productBiz_networkError'.trParams({
              'code': '${e.response?.statusCode ?? '-'}',
            });
      return false;
    } catch (e) {
      updateErrorText = 'productBiz_unexpectedError'.trParams({'error': '$e'});
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    updateErrorText = '';
    try {
      await _service.deleteProduct(productId);
      myProducts.removeWhere((p) => p.id == productId);
      return true;
    } on DioException catch (e) {
      updateErrorText = 'productBiz_networkError'.trParams({
        'code': '${e.response?.statusCode ?? '-'}',
      });
      return false;
    } catch (e) {
      updateErrorText = 'productBiz_unexpectedError'.trParams({'error': '$e'});
      return false;
    }
  }

  /// Validates the form and builds a local [ProductModel] without posting.
  ProductModel? buildDraft() {
    if (!(formKey.currentState?.validate() ?? false)) return null;

    final cat = category.value;
    if (cat == null) {
      errorText.value = 'productBiz_categoryRequired'.tr;
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

      return ProductModel.draftWeight(
        title: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        market: market,
        category: cat,
        originalPrice: orig.isEmpty
            ? null
            : double.parse(orig.replaceAll(',', '.')).toStringAsFixed(2),
        pricePerKg: perKg,
        weightAvailableKg: weightKg,
        minOrderKg: minKg,
      );
    } else {
      final original = double.parse(originalCtrl.text.replaceAll(',', '.'));
      final price = double.parse(priceCtrl.text.replaceAll(',', '.'));

      return ProductModel.draft(
        title: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        market: market,
        category: cat,
        originalPrice: original.toStringAsFixed(2),
        price: price.toStringAsFixed(2),
        quantity: quantity.value,
      );
    }
  }

  /// Validates the form, builds a draft, and POSTs it. Returns the created
  /// model, or null with [errorText] set on failure.
  Future<ProductModel?> submit() async {
    final draft = buildDraft();
    if (draft == null) return null;

    isSaving.value = true;
    errorText.value = '';

    try {
      final body = draft.toPostJson();
      final created = await _service.createProduct(body);
      resetForm();
      return created;
    } on DioException catch (e) {
      final d = e.response?.data;
      errorText.value = (d is Map && d['hydra:description'] != null)
          ? d['hydra:description'].toString()
          : 'productBiz_networkError'.trParams({
              'code': '${e.response?.statusCode ?? '-'}',
            });
      return null;
    } catch (e) {
      errorText.value = 'productBiz_unexpectedError'.trParams({'error': '$e'});
      return null;
    } finally {
      isSaving.value = false;
    }
  }
}
