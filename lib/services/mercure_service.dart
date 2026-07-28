import 'dart:async';
import 'dart:convert';

import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:food_app/constants/api_constants.dart';
import 'package:food_app/utils/app_logger.dart';

/// The "new offer" payload the backend publishes to a city-scoped Mercure
/// topic (`food-products/city/{citySlug}`) when a new offer goes live. This is
/// intentionally a small subset of FoodOfferModel's fields, not the full
/// model — use it to trigger a refetch or show a toast, not to render an
/// offer card directly.
class MercureOfferEvent {
  MercureOfferEvent({
    required this.id,
    required this.title,
    this.businessName,
    this.price,
    this.city,
  });

  factory MercureOfferEvent.fromJson(Map<String, dynamic> json) {
    return MercureOfferEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      businessName: json['businessName'] as String?,
      price: (json['salePrice'] ?? json['price'])?.toString(),
      city: json['city'] as String?,
    );
  }

  final int id;
  final String title;
  final String? businessName;
  final String? price;
  final String? city;
}

/// The stock/expiry payload the backend publishes to a single offer's public
/// topic (`food-products/{offerId}`) whenever quantity/weight remaining
/// changes or the offer expires. Small enough to patch the open detail
/// screen's local state in place instead of refetching the whole offer.
class OfferStockMercureEvent {
  OfferStockMercureEvent({
    required this.id,
    required this.status,
    this.quantityAvailable,
    this.weightAvailableKg,
  });

  factory OfferStockMercureEvent.fromJson(Map<String, dynamic> json) {
    return OfferStockMercureEvent(
      id: json['id'] as int,
      status: json['status'] as String,
      quantityAvailable: json['quantityAvailable'] as int?,
      weightAvailableKg: (json['weightAvailableKg'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String status;
  final int? quantityAvailable;
  final double? weightAvailableKg;
}

/// The open/closed payload the backend publishes to a business's public
/// status topic (`business-partners/{id}/status`) whenever the partner
/// toggles open/closed or closes permanently.
class BusinessStatusMercureEvent {
  BusinessStatusMercureEvent({
    required this.id,
    required this.isActive,
    this.closedAt,
  });

  factory BusinessStatusMercureEvent.fromJson(Map<String, dynamic> json) {
    return BusinessStatusMercureEvent(
      id: json['id'] as int,
      isActive: json['isActive'] as bool? ?? true,
      closedAt: json['closedAt'] as String?,
    );
  }

  final int id;
  final bool isActive;
  final String? closedAt;

  bool get isClosed => closedAt != null;
}

/// The order-update payload the backend publishes to a business's private
/// orders topic (`business-partners/{id}/orders`) on a new order. Like
/// [MercureOfferEvent], a small subset of OrderModel's fields — use it to
/// trigger a refetch, not to render the order directly.
class OrderMercureEvent {
  OrderMercureEvent({
    required this.id,
    required this.status,
    this.businessName,
    this.subtotal,
    this.itemCount,
  });

  factory OrderMercureEvent.fromJson(Map<String, dynamic> json) {
    return OrderMercureEvent(
      // The backend publishes the numeric DB id here, not the order's UUID
      // (OrderModel.id) — toString() so either shape decodes without crashing.
      id: json['id'].toString(),
      status: json['status'] as String,
      businessName: json['businessName'] as String?,
      subtotal: json['subtotal']?.toString(),
      itemCount: json['itemCount'] as int?,
    );
  }

  final String id;
  final String status;
  final String? businessName;
  final String? subtotal;
  final int? itemCount;
}

/// The status-change payload the backend publishes to a customer's own
/// private orders topic (`users/{id}/orders`) — a different, smaller shape
/// than [OrderMercureEvent]: just enough to know which order changed and
/// trigger the same refresh the `order_status_changed` FCM push already
/// calls.
class UserOrderMercureEvent {
  UserOrderMercureEvent({required this.orderId, required this.status});

  factory UserOrderMercureEvent.fromJson(Map<String, dynamic> json) {
    return UserOrderMercureEvent(
      orderId: json['orderId'].toString(),
      status: json['status'] as String,
    );
  }

  final String orderId;
  final String status;
}

/// The new-review payload the backend publishes to a business's private
/// reviews topic (`business-partners/{id}/reviews`) whenever a customer
/// submits a review. Small subset of ReviewModel's fields (matches
/// ReviewProcessor::notifyBusinessOfNewReview's payload) — use it to trigger
/// a refetch of the reviews list / business average rating, not to render
/// the review directly.
class ReviewMercureEvent {
  ReviewMercureEvent({
    required this.id,
    this.rating,
    this.comment,
    this.reviewer,
  });

  factory ReviewMercureEvent.fromJson(Map<String, dynamic> json) {
    return ReviewMercureEvent(
      id: json['id'].toString(),
      rating: (json['rating'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      reviewer: json['reviewer'] as String?,
    );
  }

  final String id;
  final int? rating;
  final String? comment;
  final String? reviewer;
}

/// Subscribes to the backend's Mercure hub for real-time updates over
/// Server-Sent Events (SSE).
class MercureService {
  const MercureService();

  static const _tag = 'MercureService';

  /// Dummy IRI base the backend's Mercure publisher uses for PUBLIC topic
  /// names (confirmed working for the food-offers topic — see
  /// [[project_mercure_realtime]]). Private topics never need this: they
  /// come back verbatim in the `topics` array from `GET /me/mercure-token`.
  static const String _publicTopicBase = 'https://api.template.local/';

  /// Turns a free-form city name into the slug the backend expects in the
  /// `food-products/city/{citySlug}` topic: lowercase, accents stripped
  /// (München → munchen), spaces/punctuation collapsed to single hyphens.
  static String citySlug(String city) {
    const accented =
        'àáâãäåāăąçćčđďèéêëēĕėęěğǵḧìíîïĩīĭįıĵķłĺļľñńņňòóôõöøōŏőŕřßśšşťţùúûüũūŭůűųẃẍÿýźžż';
    const plain =
        'aaaaaaaaacccddeeeeeeeeeegghiiiiiiiijklllnnnooooooooorrssstuuuuuuuuuuwxyyzzz';

    final buffer = StringBuffer();
    for (final rune in city.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final idx = accented.indexOf(ch);
      buffer.write(idx == -1 ? ch : plain[idx]);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Public topic for new-offer alerts in [citySlug] — no auth required.
  static String foodOffersTopicForCity(String citySlug) =>
      '${_publicTopicBase}food-products/city/$citySlug';

  /// Public topic for stock/expiry changes on a single offer.
  static String offerStockTopic(int offerId) =>
      '${_publicTopicBase}food-products/$offerId';

  /// Public topic for a business's open/closed status.
  static String businessStatusTopic(int businessId) =>
      '${_publicTopicBase}business-partners/$businessId/status';

  /// Opens an SSE connection to the city-scoped new-offer topic and calls
  /// [onOffer] for every decoded event. Cancel the returned subscription
  /// (e.g. from a controller's `onClose`) to stop listening.
  StreamSubscription<SSEModel> subscribeToFoodOffers({
    required String citySlug,
    required void Function(MercureOfferEvent offer) onOffer,
  }) {
    return _subscribe(
      topic: foodOffersTopicForCity(citySlug),
      decode: MercureOfferEvent.fromJson,
      onEvent: onOffer,
    );
  }

  /// Opens an SSE connection to a single offer's public stock/expiry topic.
  StreamSubscription<SSEModel> subscribeToOfferStock({
    required int offerId,
    required void Function(OfferStockMercureEvent stock) onStock,
  }) {
    return _subscribe(
      topic: offerStockTopic(offerId),
      decode: OfferStockMercureEvent.fromJson,
      onEvent: onStock,
    );
  }

  /// Opens an SSE connection to a business's public open/closed topic.
  StreamSubscription<SSEModel> subscribeToBusinessStatus({
    required int businessId,
    required void Function(BusinessStatusMercureEvent status) onStatus,
  }) {
    return _subscribe(
      topic: businessStatusTopic(businessId),
      decode: BusinessStatusMercureEvent.fromJson,
      onEvent: onStatus,
    );
  }

  /// Opens an SSE connection to a business's private orders [topic] (from
  /// [MercureController.businessOrdersTopic]), using [token]
  /// ([MercureController.token]) to authorize. Skip the token and the
  /// connection "succeeds" but silently delivers nothing — the hub only
  /// pushes private updates to authorized subscribers. [token] is
  /// short-lived; re-fetch and reconnect before it expires rather than
  /// reusing an old one.
  StreamSubscription<SSEModel> subscribeToOrders({
    required String topic,
    required String token,
    required void Function(OrderMercureEvent order) onOrder,
  }) {
    return _subscribe(
      topic: topic,
      token: token,
      decode: OrderMercureEvent.fromJson,
      onEvent: onOrder,
    );
  }

  /// Opens an SSE connection to a customer's own private orders [topic]
  /// (from [MercureController.userOrdersTopic]), using [token] to authorize.
  /// Same auth caveat as [subscribeToOrders] — a missing/expired token
  /// connects successfully but silently receives nothing.
  StreamSubscription<SSEModel> subscribeToUserOrders({
    required String topic,
    required String token,
    required void Function(UserOrderMercureEvent order) onOrder,
  }) {
    return _subscribe(
      topic: topic,
      token: token,
      decode: UserOrderMercureEvent.fromJson,
      onEvent: onOrder,
    );
  }

  /// Opens an SSE connection to a business's private reviews [topic] (from
  /// [MercureController.businessReviewsTopic]), using [token] to authorize.
  /// Same auth caveat as [subscribeToOrders] — a missing/expired token
  /// connects successfully but silently receives nothing.
  StreamSubscription<SSEModel> subscribeToBusinessReviews({
    required String topic,
    required String token,
    required void Function(ReviewMercureEvent review) onReview,
  }) {
    return _subscribe(
      topic: topic,
      token: token,
      decode: ReviewMercureEvent.fromJson,
      onEvent: onReview,
    );
  }

  StreamSubscription<SSEModel> _subscribe<T>({
    required String topic,
    required T Function(Map<String, dynamic> json) decode,
    required void Function(T event) onEvent,
    String? token,
  }) {
    final url = Uri.parse(
      ApiConstants.mercureHubUrl,
    ).replace(queryParameters: {'topic': topic}).toString();

    AppLogger.info(_tag, 'Subscribing to Mercure: $url');

    return SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: url,
      header: {
        'Accept': 'text/event-stream',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).listen(
      (event) {
        final data = event.data?.trim();
        if (data == null || data.isEmpty) return;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          onEvent(decode(json));
        } catch (e, st) {
          AppLogger.error(
            _tag,
            'Failed to decode Mercure event: $data',
            error: e,
            stackTrace: st,
          );
        }
      },
      onError: (Object e, StackTrace st) {
        AppLogger.error(
          _tag,
          'Mercure SSE stream error',
          error: e,
          stackTrace: st,
        );
      },
    );
  }
}
