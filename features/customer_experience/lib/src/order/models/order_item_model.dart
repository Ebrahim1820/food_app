import 'package:models/models.dart';

class OrderItemModel {
  final int id;
  final String foodOrder;
  final FoodOfferModel foodOffer;
  final ProductModel product;

  /// The real, always-present offer/product id — `OrderItem::$productId` on
  /// the backend, a plain int column with no ORM relation since the Phase C
  /// catalog-service split (Product/FoodOffer moved out of this database).
  /// Because of that, the backend has nothing to serialize a nested
  /// `foodOffer`/`product` object from anymore, so [foodOffer] and [product]
  /// above always deserialize to an empty placeholder (id `0`) — use
  /// [offerId] (which prefers this field) for any identity matching against
  /// a real offer/product, not `foodOffer.id`/`product.id` directly.
  final int productId;
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
    this.productId = 0,
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
      productId: json['productId'] as int? ?? 0,
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
    'product': product.toJson(),
    'productId': productId,
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

  /// The real offer/product id to match against — prefers [productId] (the
  /// plain column the backend actually serializes today) and falls back to
  /// [product]/[foodOffer]'s embedded id for older responses that might
  /// still send one of those.
  int get offerId =>
      productId > 0 ? productId : (product.id > 0 ? product.id : foodOffer.id);

  OrderItemModel withOffer(FoodOfferModel offer) => OrderItemModel(
    id: id,
    foodOrder: foodOrder,
    foodOffer: offer,
    product: product,
    productId: productId,
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
