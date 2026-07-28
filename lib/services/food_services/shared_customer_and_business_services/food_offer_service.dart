import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/models/food_models/customer_models/food_section_model.dart';

/// Handles all REST calls for Food listings, backed by the generic
/// `/products` resource (filtered/tagged with `market: 'food'`).
///
/// Food offers are the surplus items that business partners list for customers
/// to reserve. This service is used in three contexts:
///   - Customer home screen (browse & search available offers)
///   - Business menu screen (manage the partner's own listings)
///   - Admin panel (review all platform offers)
class FoodOfferService {
  const FoodOfferService(this._api);

  final ApiService _api;
  static const _tag = 'FoodOfferService';
  static const int _defaultPageSize = 30;

  /// Fetches a paginated, filtered list of active food offers for customers.
  ///
  /// Only shows offers with `status=active` whose pickup window hasn't ended
  /// yet, so customers never see expired or hidden items. Supports optional
  /// title search, category filter, and sort order.
  ///
  /// The request is sent without a Bearer token (`noAuth: true`) because food
  /// offers are a public catalog — sending a token for a user unknown to
  /// Symfony would cause a 401 on this public endpoint.
  Future<List<FoodOfferModel>> getOffers({
    String? title,
    String? category,
    String? orderField,
    String? orderDirection,
    int page = 1,
    int itemsPerPage = _defaultPageSize,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'itemsPerPage': itemsPerPage.toString(),
      'status': 'active',
      'endTime[after]': DateTime.now().toUtc().toIso8601String(),
    };
    query['market'] = 'food';
    if (title != null && title.isNotEmpty) query['title'] = title;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (orderField != null && orderDirection != null) {
      query['order[$orderField]'] = orderDirection;
    }

    AppLogger.info(
      _tag,
      'GET offers page=$page category=${category ?? "all"} title=${title ?? ""}',
    );
    try {
      final res = await _api.dio.get(
        ApiEndpoints.products,
        queryParameters: query,
        options: Options(extra: {'noAuth': true}),
      );
      final List data = res.data['hydra:member'] as List;
      AppLogger.info(_tag, 'Fetched ${data.length} offer(s)');
      return data
          .map((e) => FoodOfferModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getOffers failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches all non-empty category sections for the home screen in one request.
  ///
  /// Replaces the old pattern of firing one request per category. The backend
  /// skips categories with no active offers so the response is always compact.
  Future<List<FoodSectionModel>> getSections({int limit = 10}) async {
    AppLogger.info(_tag, 'GET sections (limit=$limit)');
    try {
      final res = await _api.dio.get(
        '${ApiEndpoints.productSections}/food',
        queryParameters: {'limit': limit},
        options: Options(extra: {'noAuth': true}),
      );
      final List raw = res.data['sections'] as List;
      AppLogger.info(_tag, 'Fetched ${raw.length} section(s)');
      return raw
          .map((e) => FoodSectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getSections failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches one page of offers for a single category row (horizontal scroll).
  ///
  /// Called when the user scrolls right past the initial items. [page] comes
  /// from [FoodSectionModel.nextPage] — pass it directly to avoid off-by-one.
  Future<FoodSectionModel> getSectionPage(
    String category,
    int page, {
    int limit = 10,
  }) async {
    AppLogger.info(_tag, 'GET section/$category page=$page');
    try {
      final res = await _api.dio.get(
        '${ApiEndpoints.productSections}/food/$category',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(extra: {'noAuth': true}),
      );
      return FoodSectionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getSectionPage($category, $page) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches one page of offers belonging to a single business partner (their menu).
  ///
  /// Returns all statuses (active, inactive, expired) so the partner sees
  /// their full menu history, not just currently live items. Sorted newest first.
  Future<List<FoodOfferModel>> getBusinessOffers(
    int businessPartnerId, {
    int page = 1,
    int itemsPerPage = 20,
  }) async {
    AppLogger.info(
      _tag,
      'GET offers for partner $businessPartnerId page=$page',
    );
    try {
      final res = await _api.dio.get(
        ApiEndpoints.products,
        queryParameters: {
          'market': 'food',
          'businessPartner': '/api/business-partners/$businessPartnerId',
          'order[createdAt]': 'desc',
          'page': page.toString(),
          'itemsPerPage': itemsPerPage.toString(),
        },
      );
      final List data = (res.data['hydra:member'] as List?) ?? [];
      AppLogger.info(
        _tag,
        'Fetched ${data.length} offer(s) for partner $businessPartnerId',
      );
      return data
          .map((e) => FoodOfferModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getBusinessOffers($businessPartnerId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Creates a new food offer (business "add to menu" flow).
  ///
  /// [data] must be in API Platform shape: relations as IRI strings, money
  /// as strings, datetimes as ISO-8601. On success the API returns the created
  /// resource parsed back to a [FoodOfferModel] to avoid a redundant refetch.
  Future<FoodOfferModel> createOffer(Map<String, dynamic> data) async {
    AppLogger.info(_tag, 'POST new offer: ${data['title']}');
    try {
      final res = await _api.dio.post(
        ApiEndpoints.products,
        data: {'market': 'food', ...data},
      );
      if (res.statusCode != 201) {
        throw Exception('createOffer: unexpected HTTP ${res.statusCode}');
      }
      AppLogger.info(_tag, 'Offer created successfully');
      return FoodOfferModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'createOffer failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Partially updates an existing offer via PATCH.
  ///
  /// API Platform requires `Content-Type: application/merge-patch+json` for
  /// PATCH — only fields present in [body] are changed, everything else is
  /// left untouched on the server.
  Future<FoodOfferModel> updateOffer(
    int offerId,
    Map<String, dynamic> body,
  ) async {
    AppLogger.info(_tag, 'PATCH offer $offerId fields=${body.keys.toList()}');
    try {
      final res = await _api.dio.patch(
        '${ApiEndpoints.products}/$offerId',
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Offer $offerId updated');
      return FoodOfferModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'updateOffer($offerId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Permanently deletes an offer. This cannot be undone.
  ///
  /// The backend should also cancel any pending orders for this offer before
  /// deletion — verify this behaviour when testing.
  Future<void> deleteOffer(int offerId) async {
    AppLogger.info(_tag, 'DELETE offer $offerId');
    try {
      await _api.dio.delete('${ApiEndpoints.products}/$offerId');
      AppLogger.info(_tag, 'Offer $offerId deleted');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'deleteOffer($offerId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
