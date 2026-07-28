import 'package:dio/dio.dart';
import 'package:food_app/constants/api_endpoints.dart';
import 'package:food_app/network/api_service.dart';
import 'package:food_app/models/product_models/product_order_model.dart';
import 'package:food_app/utils/app_logger.dart';

/// Handles REST calls for the generic `/product-orders` resource — the
/// market-agnostic counterpart to the parts of `OrderService` that are
/// Food-specific. Reading order history (`GET /api/orders`) already returns
/// both Food and product-orders together (they're the same backend table),
/// so this service only needs the two operations registered on a separate
/// URI: creating an order and updating its status.
class ProductOrderService {
  const ProductOrderService(this._api);

  final ApiService _api;
  static const _tag = 'ProductOrderService';

  /// Places a new product-order. Mirrors `OrderService.placeOrder`'s body
  /// shape, except each item key is `product` (an IRI), not `foodOffer`.
  Future<void> placeOrder({
    required String businessPartnerIri,
    String? deliveryAddressIri,
    required String notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'card',
  }) async {
    AppLogger.info(
      _tag,
      'POST product-order for partner $businessPartnerIri items=${items.length}',
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
      AppLogger.info(_tag, 'Product-order placed successfully');
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
    }
  }

  /// Transitions a product-order to [newStatus] via its dedicated status
  /// sub-resource, mirroring `OrderService.updateOrderStatus`.
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? cancellationReason,
  }) async {
    AppLogger.info(_tag, 'PUT product-order $orderId status → $newStatus');
    try {
      await _api.dio.put(
        '${ApiEndpoints.orders}/$orderId/status',
        data: {
          'status': newStatus,
          if (cancellationReason != null && cancellationReason.isNotEmpty)
            'cancellationReason': cancellationReason,
        },
      );
      AppLogger.info(_tag, 'Product-order $orderId transitioned to $newStatus');
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

  Future<void> cancelOrder(String orderId, {String? reason}) =>
      updateOrderStatus(orderId, 'cancelled', cancellationReason: reason);

  /// Fetches a single product-order by id — the detail endpoint, unlike
  /// [getOrders]'s list endpoint, reliably embeds a real nested `product`
  /// (the list endpoint nulls it out, same gotcha Food's `foodOffer:null`
  /// has). Mirrors `OrderService.getOrderById`.
  Future<ProductOrderModel> getOrderById(String id) async {
    AppLogger.info(_tag, 'GET product-order $id');
    try {
      final response = await _api.dio.get('${ApiEndpoints.orders}/$id');
      return ProductOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrderById($id) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates the notes and delivery address on a pending product-order.
  /// Mirrors `OrderService.updateOrder` — same shared `/orders/{id}`
  /// resource, only allowed while the order is still `pending`.
  Future<void> updateOrder(
    String orderId, {
    required String notes,
    required String deliveryAddressIri,
  }) async {
    AppLogger.info(_tag, 'PATCH product-order $orderId');
    try {
      await _api.dio.patch(
        '${ApiEndpoints.orders}/$orderId',
        data: {'notes': notes, 'deliveryAddress': deliveryAddressIri},
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Product-order $orderId updated');
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

  /// Updates the quantity of a single product-order item. Mirrors
  /// `OrderService.updateOrderItem` — same shared `/order-items/{id}`
  /// resource.
  Future<void> updateOrderItem(int itemId, {required int quantity}) async {
    AppLogger.info(_tag, 'PATCH product-order item $itemId → quantity=$quantity');
    try {
      await _api.dio.patch(
        '${ApiEndpoints.orderItems}/$itemId',
        data: {'quantity': quantity},
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Product-order item $itemId quantity updated');
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

  /// Fetches one page of product-orders for the authenticated customer.
  /// `GET /api/orders` already returns Food and product-orders together
  /// (same backend table) — this just parses the response as
  /// [ProductOrderModel] instead of `OrderModel` so `orderItems` resolve to
  /// [ProductOrderItemModel] (`product`, not `foodOffer`).
  Future<({int total, List<ProductOrderModel> orders, bool hasNext})>
  getOrders({required String userIri, int page = 1}) async {
    AppLogger.info(_tag, 'GET product-orders for $userIri page=$page');
    try {
      final response = await _api.dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'user': userIri,
          'order[createdAt]': 'desc',
          'page': page,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final total = data['hydra:totalItems'] as int? ?? 0;
      final members = data['hydra:member'];
      if (members == null) throw Exception('Missing hydra:member in response');

      final orders = (members as List)
          .cast<Map<String, dynamic>>()
          .map((j) => ProductOrderModel.fromJson(j))
          .toList();
      final view = data['hydra:view'] as Map<String, dynamic>?;
      final hasNext = view != null && view.containsKey('hydra:next');
      return (total: total, orders: orders, hasNext: hasNext);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getOrders failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches all product-orders placed with this business partner, newest
  /// first — the business-side counterpart to [getOrders]. Mirrors
  /// `OrderService.getBusinessOrders`.
  Future<List<ProductOrderModel>> getBusinessOrders({
    required String businessPartnerIri,
  }) async {
    AppLogger.info(_tag, 'GET business product-orders for $businessPartnerIri');
    try {
      final response = await _api.dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'businessPartner': businessPartnerIri,
          'order[createdAt]': 'desc',
        },
      );
      final data = response.data as Map<String, dynamic>;
      final members = data['hydra:member'];
      if (members == null) throw Exception('Missing hydra:member in response');

      return (members as List)
          .cast<Map<String, dynamic>>()
          .map((j) => ProductOrderModel.fromJson(j))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getBusinessOrders failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
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
}
