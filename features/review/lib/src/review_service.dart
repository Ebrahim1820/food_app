import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'review_model.dart';

/// Thrown when `POST /reviews` returns 409 — this user already reviewed
/// this order (enforced by a DB unique constraint server-side).
class ReviewAlreadyExistsException implements Exception {
  const ReviewAlreadyExistsException();
}

/// Handles all REST calls for the `/reviews` resource: submitting a
/// post-order rating and reading the reviews left for a business.
class ReviewService {
  const ReviewService(this._api);

  final ApiService _api;
  static const _tag = 'ReviewService';

  /// POST /reviews — one review per (user, order) pair: a customer rates
  /// each order they complete, not just the business once.
  Future<ReviewModel> submitReview({
    required String businessPartnerId,
    required int rating,
    required String orderId,
    String? comment,
  }) async {
    AppLogger.info(
      _tag,
      'POST /reviews order=$orderId businessPartner=$businessPartnerId rating=$rating',
    );
    try {
      final response = await _api.dio.post(
        ApiEndpoints.reviews,
        data: {
          'businessPartner': ApiEndpoints.businessPartnerIri(businessPartnerId),
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
          'order': ApiEndpoints.orderIri(orderId),
        },
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 409) {
        AppLogger.info(_tag, 'Review already exists for order $orderId');
        throw const ReviewAlreadyExistsException();
      }
      AppLogger.error(
        _tag,
        'submitReview failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      throw Exception(
        _extractMessage(e.response?.data) ?? 'Could not submit review.',
      );
    }
  }

  /// GET /reviews?businessPartner={iri}&page={page} — newest first.
  Future<({List<ReviewModel> reviews, bool hasNext})> fetchForBusiness(
    String businessPartnerId, {
    int page = 1,
  }) async {
    AppLogger.info(
      _tag,
      'GET /reviews businessPartner=$businessPartnerId page=$page',
    );
    final response = await _api.dio.get(
      ApiEndpoints.reviews,
      queryParameters: {
        'businessPartner': ApiEndpoints.businessPartnerIri(businessPartnerId),
        'order[createdAt]': 'desc',
        'page': page,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final reviews = (data['hydra:member'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList();
    final view = data['hydra:view'] as Map<String, dynamic>?;
    final hasNext = view != null && view.containsKey('hydra:next');
    return (reviews: reviews, hasNext: hasNext);
  }

  /// Whether [userIri] has already reviewed [orderId] — a single cheap
  /// filtered lookup instead of pulling every review for the order's business.
  ///
  /// Deliberately re-checks each returned member against [orderId] instead of
  /// trusting `hydra:totalItems` on its own: if the backend's `order`/`user`
  /// ApiFilter isn't deployed yet, API Platform silently ignores those unknown
  /// query params and returns the *whole* unfiltered collection — trusting
  /// the raw count would then report "already reviewed" for every order as
  /// soon as anyone, anywhere, had left a single review.
  Future<bool> hasReviewedOrder(String orderId, String userIri) async {
    AppLogger.info(_tag, 'GET /reviews order=$orderId user=$userIri');
    final response = await _api.dio.get(
      ApiEndpoints.reviews,
      queryParameters: {
        'order': ApiEndpoints.orderIri(orderId),
        'user': userIri,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final members = (data['hydra:member'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return members.any(
      (m) =>
          m['order'] == ApiEndpoints.orderIri(orderId) && m['user'] == userIri,
    );
  }

  /// All order ids [userIri] has already reviewed, across every business —
  /// one bulk fetch instead of the order list checking N orders individually.
  /// Paginates fully (capped at 10 pages / ~300 reviews, a generous ceiling
  /// for a single customer) so the set this seeds is complete, not just the
  /// first page's worth.
  Future<Set<String>> fetchReviewedOrderIds(String userIri) async {
    AppLogger.info(_tag, 'GET /reviews user=$userIri (bulk)');
    final ids = <String>{};
    var page = 1;
    while (page <= 10) {
      final response = await _api.dio.get(
        ApiEndpoints.reviews,
        queryParameters: {'user': userIri, 'page': page},
      );
      final data = response.data as Map<String, dynamic>;
      final members = (data['hydra:member'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      for (final m in members) {
        if (m['user'] != userIri) continue; // defensive, see hasReviewedOrder
        final order = m['order'] as String?;
        if (order != null) ids.add(order.split('/').last);
      }
      final view = data['hydra:view'] as Map<String, dynamic>?;
      final hasNext = view != null && view.containsKey('hydra:next');
      if (!hasNext) break;
      page++;
    }
    return ids;
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['hydra:description'] ?? data['message'])
          ?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
