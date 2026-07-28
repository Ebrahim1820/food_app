import 'address_model.dart';
import 'business_partner_model.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final bool isVerified;
  final List<String> roles;
  final BusinessPartnerModel? businessPartner;
  final AddressModel? address;
  final String? createdAt;

  /// Set when the API returns businessPartner as an IRI string instead of
  /// an embedded object (e.g. "/api/business_partners/3").
  final String? businessPartnerIri;

  /// Per-Market business capability, e.g. {'food': 'owner', 'cosmetic': null}.
  /// Lets the Dashboard screen decide "business dashboard vs. customer home"
  /// per tile tap without re-deriving role/market logic client-side. See
  /// User::getBusinessCapabilities() on the backend.
  final Map<String, String?> businessCapabilities;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.isVerified,
    required this.roles,
    required this.businessPartner,
    required this.address,
    this.createdAt,
    this.businessPartnerIri,
    this.businessCapabilities = const {},
  });

  /// The business-partner ID regardless of whether the API embedded the full
  /// object or only returned the IRI reference.
  String? get effectiveBusinessPartnerId {
    if (businessPartner != null) return businessPartner!.id;
    if (businessPartnerIri != null) return businessPartnerIri!.split('/').last;
    return null;
  }

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final bpData = json['businessPartner'];
    return UserModel(
      id: json['@id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isVerified: _parseBool(json['isVerified'] ?? json['verified']),
      roles: List<String>.from(json['roles'] ?? []),
      createdAt: json['createdAt'] as String?,
      businessPartnerIri: bpData is String ? bpData : null,
      businessPartner: bpData is Map<String, dynamic>
          ? BusinessPartnerModel.fromJson(bpData)
          : null,
      address: json['address'] is Map<String, dynamic>
          ? AddressModel.fromJson(json['address'])
          : null,
      businessCapabilities: json['businessCapabilities'] is Map
          ? Map<String, dynamic>.from(
              json['businessCapabilities'] as Map,
            ).map((k, v) => MapEntry(k, v as String?))
          : const {},
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'roles': roles,
    };
  }
}
