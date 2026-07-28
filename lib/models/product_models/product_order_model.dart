import 'package:food_app/models/business_partner_model.dart';
import 'package:food_app/models/user_model.dart';
import 'package:food_app/models/product_models/product_order_item_model.dart';

/// An order placed against the generic Product catalog — the market-agnostic
/// counterpart to `OrderModel` (which stays Food-only). Both models describe
/// rows in the same backend `order`/`order_item` tables; this one just reads
/// `orderItems` as [ProductOrderItemModel] (referencing `product`, not
/// `foodOffer`).
class ProductOrderModel {
  final String id;
  final UserModel? user;
  final BusinessPartnerModel businessPartner;
  final String status;
  final String totalPrice;
  final String subtotal;
  final String deliveryFee;
  final String createdAt;
  final String updatedAt;
  final String? notes;
  final String? deliveryAddress;
  final String? estimatedDeliveryLabel;
  final String? completedAt;
  final String? cancelledAt;
  final List<ProductOrderItemModel> orderItems;
  final String paymentMethod;
  final String paymentStatus;
  final String? cancellationReason;

  const ProductOrderModel({
    required this.id,
    required this.user,
    required this.businessPartner,
    required this.status,
    required this.totalPrice,
    required this.subtotal,
    required this.deliveryFee,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.deliveryAddress,
    this.estimatedDeliveryLabel,
    this.completedAt,
    this.cancelledAt,
    required this.orderItems,
    this.paymentMethod = 'card',
    this.paymentStatus = 'pending',
    this.cancellationReason,
  });

  factory ProductOrderModel.fromJson(Map<String, dynamic> json) {
    return ProductOrderModel(
      id: _extractId(json['@id'] ?? ''),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      businessPartner: BusinessPartnerModel.fromJson(
        json['businessPartner'] ?? {},
      ),
      status: json['status'] ?? '',
      totalPrice: json['totalPrice'] ?? '0',
      subtotal: json['subtotal'] ?? '0',
      deliveryFee: json['deliveryFee'] ?? '0',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      notes: json['notes'],
      deliveryAddress:
          json['deliveryAddressSnapshot'] ?? json['deliveryAddress'],
      estimatedDeliveryLabel: json['estimatedDeliveryLabel'],
      completedAt: json['completedAt'],
      cancelledAt: json['cancelledAt'],
      orderItems: json['orderItems'] != null
          ? (json['orderItems'] as List)
                .map((e) => ProductOrderItemModel.fromJson(e))
                .toList()
          : [],
      paymentMethod: _validPaymentMethod(json['paymentMethod']),
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    '@id': '/api/orders/$id',
    'user': user?.toJson(),
    'businessPartner': businessPartner.toJson(),
    'status': status,
    'totalPrice': totalPrice,
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'notes': notes,
    'deliveryAddressSnapshot': deliveryAddress,
    'estimatedDeliveryLabel': estimatedDeliveryLabel,
    'completedAt': completedAt,
    'cancelledAt': cancelledAt,
    'orderItems': orderItems.map((e) => e.toJson()).toList(),
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
  };

  ProductOrderModel copyWith({
    String? id,
    UserModel? user,
    BusinessPartnerModel? businessPartner,
    String? status,
    String? totalPrice,
    String? subtotal,
    String? deliveryFee,
    String? createdAt,
    String? updatedAt,
    String? notes,
    String? deliveryAddress,
    String? estimatedDeliveryLabel,
    String? completedAt,
    String? cancelledAt,
    List<ProductOrderItemModel>? orderItems,
    String? paymentMethod,
    String? paymentStatus,
    String? cancellationReason,
  }) {
    return ProductOrderModel(
      id: id ?? this.id,
      user: user ?? this.user,
      businessPartner: businessPartner ?? this.businessPartner,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      estimatedDeliveryLabel:
          estimatedDeliveryLabel ?? this.estimatedDeliveryLabel,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      orderItems: orderItems ?? this.orderItems,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  static String _extractId(String iri) => iri.split('/').last;

  static String _validPaymentMethod(dynamic value) {
    if (value == 'cash') return 'cash';
    return 'card';
  }
}
