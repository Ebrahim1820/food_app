import 'package:food_app/models/product_models/product_model.dart'; // Adjust path to your ProductModel
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_section.dart';

/// One category row on the home screen for generic products.
///
/// Returned by GET /api/products/sections (all rows) and
/// GET /api/products/sections/{category}?page=N (one row, next page).
///
/// Implements the generic [MarketSection] so this list can be handed
/// straight to CustomerDiscoveryScreen without any copying/mapping.
class ProductSectionModel implements MarketSection<ProductModel> {
  @override
  final String category;
  @override
  final String label;
  @override
  final int total;
  final int limit;
  @override
  final bool hasMore;
  final int? nextPage;
  @override
  final List<ProductModel> items;

  const ProductSectionModel({
    required this.category,
    required this.label,
    required this.total,
    required this.limit,
    required this.hasMore,
    this.nextPage,
    required this.items,
  });

  factory ProductSectionModel.fromJson(Map<String, dynamic> json) {
    return ProductSectionModel(
      category: json['category'] as String,
      label: json['label'] as String,
      total: json['total'] as int,
      limit: json['limit'] as int? ?? 10,
      hasMore: json['hasMore'] as bool,
      nextPage: json['nextPage'] as int?,
      items: (json['items'] as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'label': label,
    'total': total,
    'limit': limit,
    'hasMore': hasMore,
    'nextPage': nextPage,
    'items': items.map((o) => o.toJson()).toList(),
  };

  /// Returns a copy with [more] items appended and pagination state updated.
  ProductSectionModel appendPage({
    required List<ProductModel> more,
    required bool hasMore,
    required int? nextPage,
    required int limit,
  }) {
    return ProductSectionModel(
      category: category,
      label: label,
      total: total,
      limit: limit,
      hasMore: hasMore,
      nextPage: nextPage,
      items: [...items, ...more],
    );
  }
}
