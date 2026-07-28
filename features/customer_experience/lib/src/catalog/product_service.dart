import 'package:dio/dio.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'dart:convert';

/// Handles all REST calls for the generic `/products` resource — the
/// market-agnostic counterpart to `FoodOfferService`. Every market beyond
/// Food (Cosmetic today, more later) shares this one service instead of
/// getting its own copy.
class ProductService {
  const ProductService(this._api);

  final ApiService _api;
  static const _tag = 'ProductService';
  static const int _defaultPageSize = 30;

  /// Fetches a paginated, filtered list of products for customers, scoped to
  /// one [market] (e.g. 'cosmetic'). Sent without a Bearer token (`noAuth:
  /// true`) since product listings are a public catalog, same as food offers.
  Future<List<ProductModel>> getProducts({
    required String market,
    String? category,
    String? title,
    String? orderField,
    String? orderDirection,
    int page = 1,
    int itemsPerPage = _defaultPageSize,
  }) async {
    final query = <String, dynamic>{
      'market': market,
      'page': page.toString(),
      'status': 'active',
      'itemsPerPage': itemsPerPage.toString(),
    };
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (title != null && title.isNotEmpty) query['title'] = title;
    if (orderField != null && orderDirection != null) {
      query['order[$orderField]'] = orderDirection;
    }

    AppLogger.info(
      _tag,
      'GET products market=$market page=$page category=${category ?? "all"}',
    );
    try {
      final res = await _api.dio.get(
        ApiEndpoints.products,
        queryParameters: query,
        options: Options(extra: {'noAuth': true}),
      );
      final List data = res.data['hydra:member'] as List;

      AppLogger.info(_tag, 'Fetched ${data.length} product(s)');
      return data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getProducts failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches a single product by its IRI (e.g. `/api/products/12`) — used to
  /// re-check live availability (stock/expiry) for an item already sitting
  /// in a cart. Mirrors OrderService.getFoodOfferByIri: returns null instead
  /// of throwing so a deleted/404'd product is simply treated as
  /// unavailable rather than crashing the caller.
  Future<ProductModel?> getProductByIri(String iri) async {
    AppLogger.info(_tag, 'GET product by IRI $iri');
    try {
      // The IRI includes /api (e.g. /api/products/12). Strip the prefix
      // because Dio's base URL already ends with /api.
      final path = iri.startsWith('/api') ? iri.substring(4) : iri;
      final response = await _api.dio.get(path);
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getProductByIri($iri) failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Re-fetches [iri] fresh and reports whether it's still orderable — used
  /// by [CartItem.checkAvailability] so a cart line always reflects live
  /// stock whenever it's actually checked, regardless of how long it's been
  /// sitting in the cart. Market-agnostic (Food and every other market's
  /// cards/detail screens all produce [ProductModel] items backed by this
  /// same `/api/products/{id}` resource), so this is the one checker every
  /// cart-adding call site should use.
  Future<CartItemAvailability> checkCartAvailability(String iri) async {
    final fresh = await getProductByIri(iri);
    final expired =
        fresh?.endTime != null && DateTime.now().isAfter(fresh!.endTime!);
    if (fresh == null || fresh.isSoldOut || expired) {
      return const CartItemAvailability(isAvailable: false);
    }
    return CartItemAvailability(
      isAvailable: true,
      unitPrice: fresh.isWeightBased
          ? fresh.pricePerKg
          : double.tryParse(fresh.price ?? ''),
      maxQuantity: (fresh.quantityAvailable ?? 1).toDouble(),
      maxWeightKg: fresh.weightAvailableKg ?? 1,
    );
  }

  /// Fetches one page of products belonging to a single business partner
  /// (their "My Products" list), across all statuses.
  Future<List<ProductModel>> getBusinessProducts(
    int businessPartnerId, {
    int page = 1,
    int itemsPerPage = 20,
  }) async {
    AppLogger.info(
      _tag,
      'GET products for partner $businessPartnerId page=$page',
    );
    try {
      final res = await _api.dio.get(
        ApiEndpoints.products,
        queryParameters: {
          'businessPartner': '/api/business-partners/$businessPartnerId',
          'order[createdAt]': 'desc',
          'page': page.toString(),
          'itemsPerPage': itemsPerPage.toString(),
        },
      );
      final List data = (res.data['hydra:member'] as List?) ?? [];
      AppLogger.info(
        _tag,
        'Fetched ${data.length} product(s) for partner $businessPartnerId',
      );
      return data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getBusinessProducts($businessPartnerId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Creates a new product (business "publish a listing" flow).
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    AppLogger.info(_tag, 'POST new product: ${data['title']}');
    try {
      final res = await _api.dio.post(ApiEndpoints.products, data: data);
      if (res.statusCode != 201) {
        throw Exception('createProduct: unexpected HTTP ${res.statusCode}');
      }
      AppLogger.info(_tag, 'Product created successfully');
      return ProductModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'createProduct failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Partially updates an existing product via PATCH.
  Future<ProductModel> updateProduct(
    int productId,
    Map<String, dynamic> body,
  ) async {
    AppLogger.info(
      _tag,
      'PATCH product $productId fields=${body.keys.toList()}',
    );
    try {
      final res = await _api.dio.patch(
        '${ApiEndpoints.products}/$productId',
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Product $productId updated');
      return ProductModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'updateProduct($productId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Permanently deletes a product. This cannot be undone.
  Future<void> deleteProduct(int productId) async {
    AppLogger.info(_tag, 'DELETE product $productId');
    try {
      await _api.dio.delete('${ApiEndpoints.products}/$productId');
      AppLogger.info(_tag, 'Product $productId deleted');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'deleteProduct($productId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches all non-empty category sections for a given market.
  ///
  /// Example route: GET /api/products/sections/food?limit=10
  Future<List<ProductSectionModel>> getSections({
    int limit = 10,
    required String market,
  }) async {
    AppLogger.info(_tag, 'GET sections (market=$market, limit=$limit)');
    try {
      final res = await _api.dio.get(
        '${ApiEndpoints.productSections}/$market',
        queryParameters: {'limit': limit},
        options: Options(extra: {'noAuth': true}),
      );

      final List raw = res.data['sections'] as List;

      // AppLogger.info(_tag, const JsonEncoder.withIndent('  ').convert(raw));
      AppLogger.info(
        _tag,
        'Fetched ${raw.length} section(s) for market: $market',
      );
      return raw
          .map((e) => ProductSectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getSections($market) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches paginated items for a specific category row in a market.
  ///
  /// Example route: GET /api/products/sections/food/pizza?page=2&limit=10
  Future<ProductSectionModel> getSectionPage({
    required String market,
    required String category,
    required int page,
    int limit = 10,
  }) async {
    AppLogger.info(_tag, 'GET section/$market/$category page=$page');
    try {
      final res = await _api.dio.get(
        '${ApiEndpoints.productSections}/$market/$category',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(extra: {'noAuth': true}),
      );

      // The backend directly returns the normalized section array map
      return ProductSectionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getSectionPage($market, $category, $page) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
