import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:food_app/utils/id_parse.dart';

class OrderItemModel {
  final int id;
  final String foodOrder;
  final FoodOfferModel foodOffer;
  final ProductModel product;
  final int quantity;
  final double? weightKg; // weight per item (always 1 item for weight-based)
  final double? weightTotalKg; // total weight ordered (weightKg × quantity)
  final String unitPrice;
  final String totalPrice;
  final String createdAt;
  final String updatedAt;

  /// Snapshot of the offer title at order time — reliable even if the offer is later deleted.
  final String titleSnapshot;

  /// Snapshot of the offer category at order time.
  final String categorySnapshot;

  OrderItemModel({
    required this.id,
    required this.foodOrder,
    required this.foodOffer,
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

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawOffer = json['foodOffer'];
    final offer = rawOffer is Map<String, dynamic>
        ? FoodOfferModel.fromJson(rawOffer)
        : FoodOfferModel.fromIri(rawOffer is String ? rawOffer : '');
    final rawProduct = json['product'];
    final product = rawProduct is Map<String, dynamic>
        ? ProductModel.fromJson(rawProduct)
        : ProductModel.fromIri(rawProduct is String ? rawProduct : '');
    return OrderItemModel(
      id: json['@id'] != null
          ? IdParser.fromIri(json['@id'])
          : (json['id'] as int? ?? 0),
      foodOrder: json['foodOrder'] ?? '',
      foodOffer: offer,
      product: product,
      quantity: json['quantity'] ?? 0,
      weightKg: double.tryParse(json['weightKg']?.toString() ?? ''),
      weightTotalKg: double.tryParse(json['weightTotalKg']?.toString() ?? ''),
      unitPrice: json['unitPrice'] ?? '0.00',
      totalPrice: json['totalPrice'] ?? '0.00',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      // Fall back to the embedded offer title/category if snapshot is absent
      // (old API responses that predate the snapshot fields).
      titleSnapshot: json['titleSnapshot'] as String? ?? offer.title,
      categorySnapshot: json['categorySnapshot'] as String? ?? offer.category,
    );
  }

  Map<String, dynamic> toJson() => {
    '@id': '/api/order-items/$id',
    'foodOrder': foodOrder,
    'foodOffer': foodOffer.toJson(),
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

  /// Resolves to whichever of [product]/[foodOffer] the backend actually
  /// populated for this response (the order list endpoint is known to send
  /// one of the two as null depending on market/endpoint — see the caller in
  /// `OrderController._itemsForRestore`). Both now back the same underlying
  /// row/id, so either is equally valid once non-zero.
  int get offerId => product.id > 0 ? product.id : foodOffer.id;

  OrderItemModel withOffer(FoodOfferModel offer) => OrderItemModel(
    id: id,
    foodOrder: foodOrder,
    foodOffer: offer,
    product: product,
    quantity: quantity,
    weightKg: weightKg,
    weightTotalKg: weightTotalKg,
    unitPrice: unitPrice,
    totalPrice: totalPrice,
    createdAt: createdAt,
    updatedAt: updatedAt,
    titleSnapshot: titleSnapshot,
    categorySnapshot: categorySnapshot,
  );
}
