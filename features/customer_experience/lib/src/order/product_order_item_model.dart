import 'package:models/models.dart';

/// One line item inside a [ProductOrderModel] — the generic, market-agnostic
/// counterpart to `OrderItemModel` (which stays Food-only, hardcoding a
/// `FoodOfferModel foodOffer` field). This one references [ProductModel]
/// instead, matching how the backend's `OrderItem::$product` relation is
/// separate from `OrderItem::$foodOffer`.
class ProductOrderItemModel {
  final int id;
  final String productOrder;
  final ProductModel product;
  final int quantity;
  final double? weightKg;
  final double? weightTotalKg;
  final String unitPrice;
  final String totalPrice;
  final String createdAt;
  final String updatedAt;
  final String titleSnapshot;
  final String categorySnapshot;

  const ProductOrderItemModel({
    required this.id,
    required this.productOrder,
    required this.product,
    required this.quantity,
    this.weightKg,
    this.weightTotalKg,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
    this.titleSnapshot = '',
    this.categorySnapshot = '',
  });

  factory ProductOrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'];
    final product = rawProduct is Map<String, dynamic>
        ? ProductModel.fromJson(rawProduct)
        : ProductModel.fromIri(rawProduct is String ? rawProduct : '');
    return ProductOrderItemModel(
      id: json['@id'] != null
          ? IdParser.fromIri(json['@id'])
          : (json['id'] as int? ?? 0),
      productOrder: json['foodOrder'] ?? '',
      product: product,
      quantity: json['quantity'] ?? 0,
      weightKg: double.tryParse(json['weightKg']?.toString() ?? ''),
      weightTotalKg: double.tryParse(json['weightTotalKg']?.toString() ?? ''),
      unitPrice: json['unitPrice'] ?? '0.00',
      totalPrice: json['totalPrice'] ?? '0.00',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      titleSnapshot: json['titleSnapshot'] as String? ?? product.title,
      categorySnapshot: json['categorySnapshot'] as String? ?? product.category,
    );
  }

  Map<String, dynamic> toJson() => {
    '@id': '/api/order-items/$id',
    'foodOrder': productOrder,
    'product': product.toJson(),
    'quantity': quantity,
    if (weightKg != null) 'weightKg': weightKg.toString(),
    if (weightTotalKg != null) 'weightTotalKg': weightTotalKg.toString(),
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'titleSnapshot': titleSnapshot,
    'categorySnapshot': categorySnapshot,
  };
}
