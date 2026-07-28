import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/models/user_model.dart';

/// Handles all REST calls for the `/orders` and `/order_items` resources.
///
/// Used in three contexts:
///   - Customer side: placing orders, viewing order history, editing pending orders
///   - Business partner side: viewing incoming orders, updating order status
///   - Shared: cancelling orders, fetching single order details
class OrderService {
  const OrderService(this._api);

  final ApiService _api;
  static const _tag = 'OrderService';

  // ── Customer orders ────────────────────────────────────────────────────────

  /// Fetches one page of orders for the authenticated user, newest first.
  ///
  /// [userIri] is required as a query filter so the backend scopes results
  /// to this user only (avoids the 401 returned by the unfiltered admin endpoint).
  /// Returns the order list and a flag indicating whether a next page exists.
  Future<({int totalOrders, List<OrderModel> orders, bool hasNext})> getOrders({
    required String userIri,
    int page = 1,
  }) async {
    AppLogger.info(_tag, 'GET orders for $userIri page=$page');
    try {
      final response = await _api.dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'user': userIri,
          'order[createdAt]': 'desc',
          'page': page,
        },
      );

      final int totalOrders = response.data['hydra:totalItems'] ?? 0;

      final data = response.data as Map<String, dynamic>;
      if (data['hydra:member'] == null) {
        throw Exception('Invalid response format: missing hydra:member');
      }
      final orders = (data['hydra:member'] as List)
          .cast<Map<String, dynamic>>()
          .map((j) => OrderModel.fromJson(j))
          .toList();
      final view = data['hydra:view'] as Map<String, dynamic>?;
      final hasNext = view != null && view.containsKey('hydra:next');
      AppLogger.info(
        _tag,
        'Fetched ${orders.length} orders (page $page) hasNext=$hasNext',
      );
      return (totalOrders: totalOrders, orders: orders, hasNext: hasNext);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrders failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrders unexpected error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches a single order by its string [id].
  ///
  /// Used to refresh the order detail screen after a status update so the UI
  /// always shows the latest data from the server.
  Future<OrderModel> getOrderById(String id) async {
    AppLogger.info(_tag, 'GET order $id');
    try {
      final response = await _api.dio.get('${ApiEndpoints.orders}/$id');
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrderById($id) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrderById($id) unexpected error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches a food offer by its API Platform IRI.
  ///
  /// Used to populate missing image data on order items without a separate
  /// FoodOfferService import. Returns null instead of throwing so a missing
  /// image doesn't break the order detail screen.
  Future<FoodOfferModel?> getFoodOfferByIri(String iri) async {
    AppLogger.info(_tag, 'GET food offer by IRI $iri');
    try {
      // The IRI includes /api (e.g. /api/food_offers/12). Strip the prefix
      // because Dio's base URL already ends with /api.
      final path = iri.startsWith('/api') ? iri.substring(4) : iri;
      final response = await _api.dio.get(path);
      return FoodOfferModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getFoodOfferByIri($iri) failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Returns the API Platform IRI for the currently authenticated user
  /// (e.g. `/api/users/some-uuid`) by reading the response from `GET /users/me`.
  ///
  /// The IRI is cached in the controller after the first call so this endpoint
  /// is not hit on every order request.
  Future<String> fetchMyUserIri() async {
    AppLogger.info(_tag, 'GET /users/me → resolve user IRI');
    try {
      final response = await _api.dio.get('/users/me');
      final data = response.data as Map<String, dynamic>;

      // API Platform IRI — preferred when available.
      final iri = data['@id'] as String?;
      if (iri != null && iri.isNotEmpty) return iri;

      // UUID identifier (the User resource uses uuid, not a numeric id).
      final uuid = data['uuid'] as String?;
      if (uuid != null && uuid.isNotEmpty) return '/api/users/$uuid';

      // Last resort: numeric id.
      final numericId = data['id'];
      if (numericId != null) return '/api/users/$numericId';

      throw Exception('Could not resolve user IRI from /users/me: $data');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchMyUserIri failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches the full profile of the currently authenticated user.
  /// Used to read [UserModel.isVerified] for the email-verification gate.
  Future<UserModel?> fetchCurrentUser() async {
    AppLogger.info(_tag, 'GET /users/me → UserModel');
    try {
      final response = await _api.dio.get('/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchCurrentUser failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      return null;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchCurrentUser unexpected error',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Places a new order and returns the canonical user IRI from the 201 response.
  ///
  /// The returned IRI is cached by the caller for subsequent order-list queries.
  /// [deliveryAddressIri] is omitted entirely for pickup orders — the server
  /// derives the real deliveryFee from whether it's present, so a stale
  /// value here would silently change the charged fee. `user` and
  /// `deliveryFee` are never sent: `user` is inferred server-side from the
  /// token and isn't part of the schema anymore, and `deliveryFee` is
  /// display-only (read from the business partner, never submitted).
  Future<String?> placeOrder({
    required String businessPartnerIri,
    String? deliveryAddressIri,
    required String notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'card',
  }) async {
    AppLogger.info(
      _tag,
      'POST order for partner $businessPartnerIri items=${items.length} '
      'pickup=${deliveryAddressIri == null}',
    );
    final body = {
      'businessPartner': businessPartnerIri,
      'status': 'pending',
      if (deliveryAddressIri != null) 'deliveryAddress': deliveryAddressIri,
      'notes': notes,
      'orderItems': items,
      'paymentMethod': paymentMethod,
    };
    try {
      final response = await _api.dio.post(ApiEndpoints.orders, data: body);
      if (response.statusCode != 201) {
        throw Exception('placeOrder: unexpected HTTP ${response.statusCode}');
      }
      AppLogger.info(_tag, 'Order placed successfully');

      // Extract the user IRI from the response so the controller can cache it.
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final raw = data['user'];
        if (raw is String && raw.isNotEmpty) return raw;
        if (raw is Map<String, dynamic>) return raw['@id'] as String?;
      }
      return null;
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'placeOrder rejected (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      final message = _extractMessage(e.response?.data);
      if (message != null) throw Exception(message);
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'placeOrder unexpected error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['hydra:description'] ?? data['message'])
          ?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  // ── Business partner orders ────────────────────────────────────────────────

  /// Fetches all orders placed with this business partner, newest first.
  ///
  /// [businessPartnerIri] is passed as a query filter so the backend can scope
  /// results for both ROLE_BUSINESS_PARTNER and ROLE_MEMBER users without
  /// exposing orders from other partners.
  Future<List<OrderModel>> getBusinessOrders({
    required String businessPartnerIri,
  }) async {
    AppLogger.info(_tag, 'GET business orders for $businessPartnerIri');
    try {
      final response = await _api.dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'businessPartner': businessPartnerIri,
          'order[createdAt]': 'desc',
        },
      );
      if (response.data == null) {
        throw Exception('Null response from orders endpoint');
      }

      final List<dynamic> rawList;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final members = data['hydra:member'];
        if (members == null) {
          throw Exception('Missing hydra:member in response');
        }
        rawList = members as List<dynamic>;
      } else if (data is List) {
        rawList = data;
      } else {
        throw Exception('Unexpected response type: ${data.runtimeType}');
      }

      final orders = rawList
          .cast<Map<String, dynamic>>()
          .map((j) => OrderModel.fromJson(j))
          .toList();
      AppLogger.info(_tag, 'Fetched ${orders.length} business order(s)');
      return orders;
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getBusinessOrders failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getBusinessOrders unexpected error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches a paginated, date-filtered history of orders for a business partner.
  ///
  /// Results are always sorted newest-first. Pagination is cursor-free (page
  /// numbers) to match the Hydra API Platform contract. The caller accumulates
  /// pages into a single list; this method returns a single page.
  Future<({int total, List<OrderModel> orders, bool hasNext})> getOrderHistory({
    required String businessPartnerIri,
    required DateTime dateFrom,
    required DateTime dateTo,
    int page = 1,
    int itemsPerPage = 20,
  }) async {
    AppLogger.info(
      _tag,
      'GET order history for $businessPartnerIri '
      'from=${dateFrom.toIso8601String()} to=${dateTo.toIso8601String()} '
      'page=$page',
    );
    try {
      final response = await _api.dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'businessPartner': businessPartnerIri,
          'order[createdAt]': 'desc',
          'createdAt[after]': dateFrom.toUtc().toIso8601String(),
          'createdAt[before]': dateTo.toUtc().toIso8601String(),
          'page': page,
          'itemsPerPage': itemsPerPage,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final int total = data['hydra:totalItems'] as int? ?? 0;
      final members = data['hydra:member'];
      if (members == null) throw Exception('Missing hydra:member in response');

      final orders = (members as List)
          .cast<Map<String, dynamic>>()
          .map((j) => OrderModel.fromJson(j))
          .toList();

      final view = data['hydra:view'] as Map<String, dynamic>?;
      final hasNext = view != null && view.containsKey('hydra:next');

      AppLogger.info(
        _tag,
        'History page $page: ${orders.length} orders, total=$total, hasNext=$hasNext',
      );
      return (total: total, orders: orders, hasNext: hasNext);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrderHistory failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrderHistory unexpected error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Updates the notes and delivery address on a pending order.
  ///
  /// Only allowed while the order is still `pending`. The business partner
  /// or admin may reject changes on already-accepted orders.
  Future<void> updateOrder(
    String orderId, {
    required String notes,
    required String deliveryAddressIri,
  }) async {
    AppLogger.info(_tag, 'PATCH order $orderId');
    try {
      await _api.dio.patch(
        '${ApiEndpoints.orders}/$orderId',
        data: {'notes': notes, 'deliveryAddress': deliveryAddressIri},
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Order $orderId updated');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'updateOrder($orderId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates the quantity of a single order item.
  ///
  /// Used on the edit-order screen where the customer can adjust item counts
  /// before the business partner accepts the order.
  Future<void> updateOrderItem(int itemId, {required int quantity}) async {
    AppLogger.info(_tag, 'PATCH order item $itemId → quantity=$quantity');
    try {
      await _api.dio.patch(
        '${ApiEndpoints.orderItems}/$itemId',
        data: {'quantity': quantity},
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Order item $itemId quantity updated');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'updateOrderItem($itemId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Transitions an order to [newStatus] via the dedicated status sub-resource.
  ///
  /// Using `PUT /orders/{id}/status` instead of PATCHing the main resource
  /// lets the backend apply business-partner-specific security separately and
  /// run status transition logic (e.g. restocking items on cancellation).
  /// [cancellationReason] is only meaningful when [newStatus] is "cancelled"
  /// — the backend now persists it directly on this same call (the old
  /// generic `PATCH /orders/{id}` this used to require has been removed).
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? cancellationReason,
  }) async {
    AppLogger.info(_tag, 'PUT order $orderId status → $newStatus');
    try {
      await _api.dio.put(
        '${ApiEndpoints.orders}/$orderId/status',
        data: {
          'status': newStatus,
          if (cancellationReason != null && cancellationReason.isNotEmpty)
            'cancellationReason': cancellationReason,
        },
      );
      AppLogger.info(_tag, 'Order $orderId transitioned to $newStatus');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'updateOrderStatus($orderId → $newStatus) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Cancels an order by setting its status to "cancelled", optionally
  /// saving [reason] as the order's cancellationReason in the same call.
  Future<void> cancelOrder(String orderId, {String? reason}) =>
      updateOrderStatus(orderId, 'cancelled', cancellationReason: reason);

  /// Permanently deletes an order record. Used by admins only.
  ///
  /// This is a hard delete — use [cancelOrder] to soft-cancel an order while
  /// keeping the record in history.
  Future<void> deleteOrder(String orderId) async {
    AppLogger.info(_tag, 'DELETE order $orderId');
    try {
      await _api.dio.delete('${ApiEndpoints.orders}/$orderId');
      AppLogger.info(_tag, 'Order $orderId deleted');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'deleteOrder($orderId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
