import 'id_parse.dart';
import 'image_model.dart';
import 'business_partner_model.dart';

/// A listing in any market beyond Food (Cosmetic today, more later) — the
/// generic counterpart to [FoodOfferModel], backed by the backend's generic
/// `Product` entity (`/api/products`, filtered by `market`). Food's own
/// listings now live on the same `/api/products` resource too (the old
/// `/api/food-offers` endpoint is gone) — [FoodOfferModel]/`FoodOfferService`
/// still exist as Food's dedicated client-side model, just repointed at the
/// same backend resource; this model is what every OTHER market shares
/// instead of getting its own copy.
class ProductModel {
  final int id;
  final String title;
  final String? description;

  /// Which market this listing belongs to, e.g. 'cosmetic'.
  final String market;
  final String category;
  final String? originalPrice;

  // ── Piece-based fields (null for weight-based products) ───────────────────
  final String? price;
  final int? quantityTotal;
  final int? quantityAvailable;

  // ── Weight-based fields (null for piece-based products) ───────────────────
  final bool isWeightBased;
  final double? weightTotalKg;
  final double? weightAvailableKg;
  final double? pricePerKg;
  final double? minOrderKg;

  /// Optional availability window — unlike Food, these are nullable: not
  /// every market needs a pickup window.
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final List<ImageModel> images;
  final BusinessPartnerModel? businessPartner;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.title,
    this.description,
    required this.market,
    required this.category,
    this.originalPrice,
    this.price,
    this.quantityTotal,
    this.quantityAvailable,
    this.isWeightBased = false,
    this.weightTotalKg,
    this.weightAvailableKg,
    this.pricePerKg,
    this.minOrderKg,
    this.startTime,
    this.endTime,
    required this.status,
    required this.images,
    required this.businessPartner,
    required this.createdAt,
  });

  /// Lightweight constructor for a piece-based product before it is saved.
  ProductModel.draft({
    required this.title,
    this.description,
    required this.market,
    required this.category,
    required this.originalPrice,
    required this.price,
    required int quantity,
  }) : id = 0,
       isWeightBased = false,
       quantityTotal = quantity,
       quantityAvailable = quantity,
       weightTotalKg = null,
       weightAvailableKg = null,
       pricePerKg = null,
       minOrderKg = null,
       startTime = null,
       endTime = null,
       status = 'active',
       images = const [],
       businessPartner = null,
       createdAt = DateTime.now();

  /// Lightweight constructor for a weight-based product before it is saved.
  ProductModel.draftWeight({
    required this.title,
    this.description,
    required this.market,
    required this.category,
    required this.originalPrice,
    required this.pricePerKg,
    required this.weightAvailableKg,
    this.minOrderKg,
  }) : id = 0,
       isWeightBased = true,
       price = null,
       quantityTotal = null,
       quantityAvailable = null,
       weightTotalKg = weightAvailableKg,
       startTime = null,
       endTime = null,
       status = 'active',
       images = const [],
       businessPartner = null,
       createdAt = DateTime.now();

  String get iri => '/api/products/$id';

  /// True when there's nothing left to order.
  bool get isSoldOut => isWeightBased
      ? (weightAvailableKg != null && weightAvailableKg! <= 0)
      : (quantityAvailable != null && quantityAvailable! <= 0);

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final weightBased = json['isWeightBased'] as bool? ?? false;

    // Safely grab salePrice or fallback to price key
    final rawPrice = json['salePrice'] ?? json['price'];

    return ProductModel(
      id: json['@id'] != null
          ? IdParser.fromIri(json['@id'])
          : (json['id'] as int? ?? 0),
      title: json['title'] ?? '',
      description: json['description'] as String?,
      market: json['market'] ?? '',
      category: json['category'] ?? '',
      originalPrice: json['originalPrice']?.toString(),
      // Fallback logic for price:
      price: rawPrice?.toString() ?? json['originalPrice']?.toString(),
      quantityTotal: json['quantityTotal'] as int?,
      quantityAvailable: json['quantityAvailable'] as int?,
      isWeightBased: weightBased,
      weightTotalKg: double.tryParse(json['weightTotalKg']?.toString() ?? ''),
      weightAvailableKg: double.tryParse(
        json['weightAvailableKg']?.toString() ?? '',
      ),
      pricePerKg: double.tryParse(json['pricePerKg']?.toString() ?? ''),
      minOrderKg: double.tryParse(json['minOrderKg']?.toString() ?? ''),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime']).toLocal()
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime']).toLocal()
          : null,
      status: json['status'] ?? '',
      images: json['images'] != null
          ? List<ImageModel>.from(
              json['images'].map((img) => ImageModel.fromJson(img)),
            )
          : [],
      businessPartner: () {
        final raw = json['businessPartner'];
        if (raw is Map<String, dynamic>) {
          return BusinessPartnerModel.fromJson(raw);
        }
        if (raw is String && raw.isNotEmpty) {
          return BusinessPartnerModel.fromIri(raw);
        }
        return null;
      }(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
    );
  }

  /// Minimal placeholder built from an IRI string when the API returns only
  /// a reference (e.g. "/api/products/42") instead of a full embedded object.
  factory ProductModel.fromIri(String iri) {
    final id = int.tryParse(iri.split('/').last) ?? 0;
    return ProductModel(
      id: id,
      title: '',
      market: '',
      category: '',
      status: '',
      images: const [],
      businessPartner: null,
      createdAt: DateTime.now(),
    );
  }

  /// POST body for creating a new product via API Platform.
  Map<String, dynamic> toPostJson() {
    final base = <String, dynamic>{
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'market': market,
      'category': category,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'isWeightBased': isWeightBased,
      if (startTime != null) 'startTime': startTime!.toUtc().toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toUtc().toIso8601String(),
    };
    if (isWeightBased) {
      base['pricePerKg'] = pricePerKg!.toStringAsFixed(2);
      base['weightTotalKg'] = weightTotalKg!.toStringAsFixed(2);
      base['weightAvailableKg'] = weightAvailableKg!.toStringAsFixed(2);
      if (minOrderKg != null) {
        base['minOrderKg'] = minOrderKg!.toStringAsFixed(2);
      }
    } else {
      base['salePrice'] = price;
      base['quantityTotal'] = quantityTotal;
      // Not sent: the server always sets quantityAvailable == quantityTotal
      // on creation.
    }
    return base;
  }

  ProductModel copyWith({
    int? id,
    String? title,
    String? description,
    String? market,
    String? category,
    String? originalPrice,
    String? price,
    int? quantityTotal,
    int? quantityAvailable,
    bool? isWeightBased,
    double? weightTotalKg,
    double? weightAvailableKg,
    double? pricePerKg,
    double? minOrderKg,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    List<ImageModel>? images,
    BusinessPartnerModel? businessPartner,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      market: market ?? this.market,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      price: price ?? this.price,
      quantityTotal: quantityTotal ?? this.quantityTotal,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      isWeightBased: isWeightBased ?? this.isWeightBased,
      weightTotalKg: weightTotalKg ?? this.weightTotalKg,
      weightAvailableKg: weightAvailableKg ?? this.weightAvailableKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      minOrderKg: minOrderKg ?? this.minOrderKg,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      images: images ?? this.images,
      businessPartner: businessPartner ?? this.businessPartner,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'market': market,
    'category': category,
    if (originalPrice != null) 'originalPrice': originalPrice,
    'isWeightBased': isWeightBased,
    if (price != null) 'salePrice': price,
    if (quantityTotal != null) 'quantityTotal': quantityTotal,
    if (quantityAvailable != null) 'quantityAvailable': quantityAvailable,
    if (weightTotalKg != null) 'weightTotalKg': weightTotalKg,
    if (weightAvailableKg != null) 'weightAvailableKg': weightAvailableKg,
    if (pricePerKg != null) 'pricePerKg': pricePerKg,
    if (minOrderKg != null) 'minOrderKg': minOrderKg,
    if (startTime != null) 'startTime': startTime!.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    'status': status,
  };
}
