import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/models/market_section.dart';

/// One category row on the home screen.
///
/// Returned by GET /api/food_offers/sections (all rows) and
/// GET /api/food_offers/sections/{category}?page=N (one row, next page).
///
/// Implements the generic [MarketSection] so this list can be handed
/// straight to CustomerDiscoveryScreen without any copying/mapping.
class FoodSectionModel implements MarketSection<FoodOfferModel> {
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
  final List<FoodOfferModel> items;

  const FoodSectionModel({
    required this.category,
    required this.label,
    required this.total,
    required this.limit,
    required this.hasMore,
    this.nextPage,
    required this.items,
  });

  factory FoodSectionModel.fromJson(Map<String, dynamic> json) {
    return FoodSectionModel(
      category: json['category'] as String,
      label: json['label'] as String,
      total: json['total'] as int,
      limit: json['limit'] as int? ?? 10,
      hasMore: json['hasMore'] as bool,
      nextPage: json['nextPage'] as int?,
      items: (json['items'] as List)
          .map((e) => FoodOfferModel.fromJson(e as Map<String, dynamic>))
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
  FoodSectionModel appendPage({
    required List<FoodOfferModel> more,
    required bool hasMore,
    required int? nextPage,
    required int limit,
  }) {
    return FoodSectionModel(
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
