import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/models/admin_stats_model.dart';
import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';

/// Provides data access for the admin dashboard.
///
/// All methods in this service are restricted to users with ROLE_ADMIN on the
/// backend. Regular customers and business partners will receive a 403 from
/// any of these endpoints, so this service should only be injected in admin
/// controllers.
class AdminService {
  const AdminService(this._api);

  final ApiService _api;
  static const _tag = 'AdminService';

  // ── Stats ──────────────────────────────────────────────────────────────────

  /// Fetches the platform-wide summary numbers shown on the admin overview tab.
  ///
  /// Runs all six count requests in parallel to reduce load time. Falls back
  /// to 0 for any individual count that fails rather than crashing the whole
  /// stats card.
  Future<AdminStats> fetchStats() async {
    AppLogger.info(_tag, 'Fetching platform stats');
    try {
      final futures = await Future.wait([
        _totalItems(ApiEndpoints.businessPartners),
        _totalItems(ApiEndpoints.users),
        _totalItems(ApiEndpoints.products),
        _totalItems(ApiEndpoints.orders),
        _safeTotalItems(ApiEndpoints.orders, {'status': 'pending'}),
        _safeTotalItems(ApiEndpoints.orders, {'status': 'cancelled'}),
      ]);
      AppLogger.info(
        _tag,
        'Stats loaded: partners=${futures[0]} customers=${futures[1]} offers=${futures[2]} orders=${futures[3]}',
      );
      return AdminStats(
        totalPartners: futures[0],
        totalCustomers: futures[1],
        totalOffers: futures[2],
        totalOrders: futures[3],
        pendingOrders: futures[4],
        cancelledOrders: futures[5],
      );
    } catch (e, st) {
      AppLogger.error(_tag, 'fetchStats failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Collections ────────────────────────────────────────────────────────────

  /// Fetches a paginated list of all business partners registered on the platform.
  ///
  /// Used in the admin Partners tab to review, approve, or suspend accounts.
  Future<AdminPage<BusinessPartnerModel>> fetchPartners({
    int page = 1,
    int limit = 30,
  }) async {
    AppLogger.info(_tag, 'GET partners page=$page');
    try {
      final res = await _api.dio.get(
        ApiEndpoints.businessPartners,
        queryParameters: {'page': page, 'itemsPerPage': limit},
      );
      final total = (res.data['hydra:totalItems'] as num?)?.toInt() ?? 0;
      final items = (res.data['hydra:member'] as List)
          .map((e) => BusinessPartnerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.info(_tag, 'Fetched ${items.length}/$total partners');
      return AdminPage(items, total);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchPartners failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches a paginated list of all registered customer accounts.
  ///
  /// Used in the admin Customers tab to view account details and verify status.
  Future<AdminPage<UserModel>> fetchCustomers({
    int page = 1,
    int limit = 100,
  }) async {
    AppLogger.info(_tag, 'GET customers page=$page');
    try {
      final res = await _api.dio.get(
        ApiEndpoints.users,
        queryParameters: {'page': page, 'itemsPerPage': limit},
      );
      final total = (res.data['hydra:totalItems'] as num?)?.toInt() ?? 0;
      final rawList = res.data['hydra:member'] as List;
      final items = rawList
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.info(_tag, 'Fetched ${items.length}/$total customers');
      return AdminPage(items, total);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchCustomers failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches all product offers across all business partners, newest first.
  ///
  /// Used in the admin Offers tab to review or remove inappropriate listings.
  Future<AdminPage<FoodOfferModel>> fetchAllOffers({
    int page = 1,
    int limit = 100,
  }) async {
    AppLogger.info(_tag, 'GET all offers page=$page');
    try {
      final res = await _api.dio.get(
        ApiEndpoints.products,
        queryParameters: {
          'market': 'food',
          'page': page,
          'itemsPerPage': limit,
          'order[createdAt]': 'desc',
        },
      );
      final total = (res.data['hydra:totalItems'] as num?)?.toInt() ?? 0;
      final items = (res.data['hydra:member'] as List)
          .map((e) => FoodOfferModel.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.info(_tag, 'Fetched ${items.length}/$total offers');
      return AdminPage(items, total);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchAllOffers failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches all orders platform-wide, optionally filtered by [status].
  ///
  /// Used in the admin Orders tab to monitor order flow and spot issues.
  /// Pass `status: 'all'` or leave it null to skip the status filter.
  Future<AdminPage<OrderModel>> fetchAllOrders({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    AppLogger.info(_tag, 'GET all orders page=$page status=${status ?? "all"}');
    try {
      final res = await _api.dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'page': page,
          'itemsPerPage': limit,
          if (status != null && status != 'all') 'status': status,
        },
      );
      final total = (res.data['hydra:totalItems'] as num?)?.toInt() ?? 0;
      final items = (res.data['hydra:member'] as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.info(_tag, 'Fetched ${items.length}/$total orders');
      return AdminPage(items, total);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchAllOrders failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ── Broadcast ──────────────────────────────────────────────────────────────

  /// POST /admin/notifications/broadcast — sends [title]/[body] as a push +
  /// notification-history row to every customer, fire-once-now (no
  /// scheduling). Returns the number of recipients so the sender gets
  /// confirmation of reach.
  Future<int> sendBroadcast({
    required String title,
    required String body,
  }) async {
    AppLogger.info(_tag, 'POST ${ApiEndpoints.adminNotificationsBroadcast}');
    try {
      final res = await _api.dio.post(
        ApiEndpoints.adminNotificationsBroadcast,
        data: {'title': title, 'body': body},
      );
      final count = (res.data['recipientCount'] as num?)?.toInt() ?? 0;
      AppLogger.info(_tag, 'Broadcast sent to $count recipient(s)');
      return count;
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'sendBroadcast failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Requests a single item from [path] and returns `hydra:totalItems`.
  /// Sending `itemsPerPage=1` avoids downloading the full collection just to
  /// count it.
  Future<int> _totalItems(String path, [Map<String, dynamic>? query]) async {
    final res = await _api.dio.get(
      path,
      queryParameters: {'itemsPerPage': 1, ...?query},
    );
    return (res.data['hydra:totalItems'] as num?)?.toInt() ?? 0;
  }

  /// Same as [_totalItems] but returns 0 instead of throwing on failure.
  /// Used for stat counts that are "nice to have" and shouldn't break the page.
  Future<int> _safeTotalItems(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    try {
      return await _totalItems(path, query);
    } catch (_) {
      return 0;
    }
  }
}

/// Generic wrapper that pairs a page of [items] with the [total] record count.
///
/// The total is needed to calculate whether more pages exist and to show
/// "X of Y" labels in the admin lists.
class AdminPage<T> {
  final List<T> items;
  final int total;
  const AdminPage(this.items, this.total);
}
