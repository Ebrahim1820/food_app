import 'package:food_app/models/address_model.dart';

class BusinessPartnerModel {
  final String id;
  final String businessName;
  final String ownerName;
  final String registrationBusinessNumber;
  final String taxNumber;
  final String createdAt;
  final String updatedAt;
  final String kycStatus;
  final List<AddressModel> addresses;
  final AddressModel? primaryAddress;
  final double rating;
  final int reviewCount;
  final String deliveryFee;

  // Prefer primaryAddress (available in list response), fall back to
  // addresses.first (available in single-object response).
  AddressModel? get _bestAddress =>
      primaryAddress ?? (addresses.isNotEmpty ? addresses.first : null);

  String get street => _bestAddress?.street ?? '';
  String get city => _bestAddress?.city ?? '';
  String get zipCode => _bestAddress?.postalCode ?? '';
  String get latitude => _bestAddress?.latitude ?? '0.0';
  String get longitude => _bestAddress?.longitude ?? '0.0';
  String? get fullAddress => _bestAddress?.fullAddress;

  final bool isActive;
  final bool acceptsCashPayment;
  final List<String> userIris;

  /// Which market(s) this business operates in, e.g. `['food']` or
  /// `['food', 'cosmetic']`. Drives which business-side "home" screen a
  /// business partner/staff account lands on after login — see
  /// `AppRoutes.businessHomeForMarkets`.
  final List<String> markets;

  bool operatesInMarket(String market) => markets.contains(market);
  final String? contactPhone;
  final String? contactEmail;

  /// Non-null when the business has been permanently closed (distinct from
  /// the day-to-day [isActive] open/closed toggle — a permanently closed
  /// business can't be reopened by flipping isActive).
  final String? closedAt;

  bool get isClosed => closedAt != null;

  BusinessPartnerModel({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.registrationBusinessNumber,
    required this.taxNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.kycStatus,
    required this.addresses,
    this.primaryAddress,
    required this.rating,
    this.reviewCount = 0,
    required this.deliveryFee,
    this.isActive = true,
    this.acceptsCashPayment = true,
    this.userIris = const [],
    this.markets = const [],
    this.contactPhone,
    this.contactEmail,
    this.closedAt,
  });

  String get iri => '/api/business-partners/$id';

  /// Integer version of [id] — needed anywhere an API call or screen expects int.
  int get numericId => int.tryParse(id) ?? 0;

  /// Creates a minimal model from just an IRI string like "/api/business_partners/1".
  /// Used when the API returns only the IRI reference instead of the full object.
  /// Defaults [isActive] to false so a stub partner never unlocks ordering.
  factory BusinessPartnerModel.fromIri(String iri) {
    return BusinessPartnerModel(
      id: iri.split('/').last,
      businessName: '',
      ownerName: '',
      registrationBusinessNumber: '',
      taxNumber: '',
      createdAt: '',
      updatedAt: '',
      kycStatus: '',
      addresses: [],
      rating: 0.0,
      deliveryFee: '0.0',
      isActive: false,
    );
  }

  factory BusinessPartnerModel.fromJson(Map<String, dynamic> json) {
    return BusinessPartnerModel(
      id: _resolveId(json),
      businessName: json['businessName'] ?? '',
      ownerName: json['ownerName'] ?? '',
      registrationBusinessNumber: json['registrationBusinessNumber'] ?? '',
      taxNumber: json['taxNumber'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      kycStatus: json['kycStatus'] ?? '',
      addresses: json['addresses'] != null
          ? (json['addresses'] as List)
                .whereType<Map<String, dynamic>>()
                .map(AddressModel.fromJson)
                .toList()
          : [],
      primaryAddress: json['primaryAddress'] is Map<String, dynamic>
          ? AddressModel.fromJson(
              json['primaryAddress'] as Map<String, dynamic>,
            )
          : null,
      rating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      deliveryFee: json['deliveryFee'] ?? '0.0',
      // isActive comes from the backend as a boolean field.
      // Default to true so existing responses without this field keep working.
      isActive: json['isActive'] as bool? ?? true,
      acceptsCashPayment: json['acceptsCashPayment'] as bool? ?? true,
      userIris:
          (json['users'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      markets:
          (json['markets'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      closedAt: json['closedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    '@id': iri,
    'businessName': businessName,
    'ownerName': ownerName,
    'registrationBusinessNumber': registrationBusinessNumber,
    'taxNumber': taxNumber,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'kycStatus': kycStatus,
    'addresses': addresses.map((a) => a.toJson()).toList(),
    if (primaryAddress != null) 'primaryAddress': primaryAddress!.toJson(),
    'averageRating': rating,
    'reviewCount': reviewCount,
    'deliveryFee': deliveryFee,
    'isActive': isActive,
    'acceptsCashPayment': acceptsCashPayment,
    'users': userIris,
    'markets': markets,
    if (contactPhone != null) 'contactPhone': contactPhone,
    if (contactEmail != null) 'contactEmail': contactEmail,
  };

  BusinessPartnerModel copyWith({
    bool? isActive,
    bool? acceptsCashPayment,
    String? contactPhone,
    String? contactEmail,
    AddressModel? primaryAddress,
    String? deliveryFee,
  }) {
    return BusinessPartnerModel(
      id: id,
      businessName: businessName,
      ownerName: ownerName,
      registrationBusinessNumber: registrationBusinessNumber,
      taxNumber: taxNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
      kycStatus: kycStatus,
      addresses: addresses,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      rating: rating,
      reviewCount: reviewCount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isActive: isActive ?? this.isActive,
      acceptsCashPayment: acceptsCashPayment ?? this.acceptsCashPayment,
      userIris: userIris,
      markets: markets,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      closedAt: closedAt,
    );
  }

  static String _resolveId(Map<String, dynamic> json) {
    final iri = json['@id'] as String?;
    if (iri != null && iri.isNotEmpty) {
      final segment = iri.split('/').last;
      if (segment.isNotEmpty) return segment;
    }
    final raw = json['id'];
    return raw?.toString() ?? '';
  }
}
