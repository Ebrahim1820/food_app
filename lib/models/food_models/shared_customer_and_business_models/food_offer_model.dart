import 'package:food_app/utils/id_parse.dart';
import 'package:food_app/models/image_model.dart';
import 'package:food_app/models/business_partner_model.dart';

class FoodOfferModel {
  final int id;
  final String title;
  final String? description;
  final String category;
  final String? originalPrice;

  // ── Piece-based fields (null for weight-based offers) ─────────────────────
  final String? price;
  final int? quantityTotal;
  final int? quantityAvailable;

  // ── Weight-based fields (null for piece-based offers) ─────────────────────
  final bool isWeightBased;
  final double? weightTotalKg;
  final double? weightAvailableKg;
  final double? pricePerKg;
  final double? minOrderKg;

  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<ImageModel> images;
  final BusinessPartnerModel? businessPartner;
  bool isFavorite;
  final DateTime createdAt;

  FoodOfferModel({
    required this.id,
    required this.title,
    this.description,
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
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.images,
    required this.businessPartner,
    this.isFavorite = false,
    required this.createdAt,
  });

  /// Lightweight constructor for a piece-based offer before it is saved.
  FoodOfferModel.draft({
    required this.title,
    this.description,
    required this.category,
    required this.originalPrice,
    required this.price,
    required int quantity,
    required this.startTime,
    required this.endTime,
  }) : id = 0,
       isWeightBased = false,
       quantityTotal = quantity,
       quantityAvailable = quantity,
       weightTotalKg = null,
       weightAvailableKg = null,
       pricePerKg = null,
       minOrderKg = null,
       status = 'active',
       images = const [],
       businessPartner = null,
       isFavorite = false,
       createdAt = DateTime.now();

  /// Lightweight constructor for a weight-based offer before it is saved.
  FoodOfferModel.draftWeight({
    required this.title,
    this.description,
    required this.category,
    required this.originalPrice,
    required this.pricePerKg,
    required this.weightAvailableKg,
    this.minOrderKg,
    required this.startTime,
    required this.endTime,
  }) : id = 0,
       isWeightBased = true,
       price = null,
       quantityTotal = null,
       quantityAvailable = null,
       weightTotalKg = weightAvailableKg,
       status = 'active',
       images = const [],
       businessPartner = null,
       isFavorite = false,
       createdAt = DateTime.now();

  String get iri => '/api/products/$id';

  /// True when there's nothing left to order — piece-based offers hit 0
  /// quantityAvailable, weight-based offers hit 0 weightAvailableKg. Offers
  /// with no stock data at all (null) are never considered sold out here.
  bool get isSoldOut => isWeightBased
      ? (weightAvailableKg != null && weightAvailableKg! <= 0)
      : (quantityAvailable != null && quantityAvailable! <= 0);

  factory FoodOfferModel.fromJson(Map<String, dynamic> json) {
    final weightBased = json['isWeightBased'] as bool? ?? false;
    return FoodOfferModel(
      id: json['@id'] != null
          ? IdParser.fromIri(json['@id'])
          : (json['id'] as int? ?? 0),
      title: json['title'] ?? '',
      description: json['description'] as String?,
      category: json['category'] ?? '',
      // Accept both new key names (post-migration) and old ones (pre-migration /
      // cached data written before this change) so stale GetStorage entries
      // don't silently zero-out prices on the first launch after the backend update.
      originalPrice: (json['originalPrice'] ?? json['originPrice'])?.toString(),
      price: (json['salePrice'] ?? json['price'])?.toString(),
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
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime']).toLocal()
          : DateTime.now(),
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

  /// Minimal placeholder built from an IRI string when the API returns only a
  /// reference (e.g. "/api/food_offers/42") instead of a full embedded object.
  factory FoodOfferModel.fromIri(String iri) {
    final id = int.tryParse(iri.split('/').last) ?? 0;
    return FoodOfferModel(
      id: id,
      title: '',
      category: '',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      status: '',
      images: const [],
      businessPartner: null,
      createdAt: DateTime.now(),
    );
  }

  /// POST body for creating a new offer via API Platform.
  Map<String, dynamic> toPostJson(int businessPartnerId) {
    final base = <String, dynamic>{
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'category': category,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'isWeightBased': isWeightBased,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'businessPartner': '/api/business-partners/$businessPartnerId',
    };
    if (isWeightBased) {
      base['pricePerKg'] = pricePerKg!.toStringAsFixed(2);
      base['weightTotalKg'] = weightTotalKg!.toStringAsFixed(2);
      base['weightAvailableKg'] = weightAvailableKg!.toStringAsFixed(2);
      if (minOrderKg != null)
        base['minOrderKg'] = minOrderKg!.toStringAsFixed(2);
    } else {
      base['salePrice'] = price;
      base['quantityTotal'] = quantityTotal;
      // Not sent: the server now always sets quantityAvailable == quantityTotal
      // on creation.
    }
    return base;
  }

  FoodOfferModel copyWith({
    int? id,
    String? title,
    String? description,
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
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return FoodOfferModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
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
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
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
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'status': status,
  };
}
