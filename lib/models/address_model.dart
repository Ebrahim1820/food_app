class AddressModel {
  final String id;
  final String? label;
  final String street;
  final String? street2;
  final String city;
  final String country;
  final String? state;
  final String postalCode;
  final String countryCode;
  final String? latitude;
  final String? longitude;

  final bool isPrimary;

  AddressModel({
    required this.id,
    this.label,
    this.isPrimary = false,
    required this.street,
    this.street2,
    required this.city,
    required this.country,
    this.state,
    required this.postalCode,
    required this.countryCode,
    this.latitude,
    this.longitude,
  });

  String get iri => '/api/addresses/$id';

  /// Returns the label value, falling back to 'other' when null.
  String get labelOrDefault => label ?? 'other';

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: _extractId(json['@id'] ?? ''),
      label: json['label'] as String?,
      isPrimary: (json['isPrimary'] as bool?) ?? false,
      street: json['street'] ?? '',
      street2: json['street2'] as String?,
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] as String?,
      postalCode: json['postalCode'] ?? '',
      countryCode: json['countryCode'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }

  static String _extractId(String iri) => iri.split('/').last;

  String get fullAddress {
    return [
      street,
      postalCode,
      city,
      country,
    ].where((e) => e.isNotEmpty).join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (label != null) 'label': label,
      'isPrimary': isPrimary,
      'street': street,
      if (street2 != null) 'street2': street2,
      'city': city,
      'country': country,
      if (state != null) 'state': state,
      'postalCode': postalCode,
      'countryCode': countryCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  AddressModel copyWith({
    String? id,
    Object? label = _sentinel,
    bool? isPrimary,
    String? street,
    Object? street2 = _sentinel,
    String? city,
    String? country,
    Object? state = _sentinel,
    String? postalCode,
    String? countryCode,
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label == _sentinel ? this.label : label as String?,
      isPrimary: isPrimary ?? this.isPrimary,
      street: street ?? this.street,
      street2: street2 == _sentinel ? this.street2 : street2 as String?,
      city: city ?? this.city,
      country: country ?? this.country,
      state: state == _sentinel ? this.state : state as String?,
      postalCode: postalCode ?? this.postalCode,
      countryCode: countryCode ?? this.countryCode,
      latitude: latitude == _sentinel ? this.latitude : latitude as String?,
      longitude: longitude == _sentinel ? this.longitude : longitude as String?,
    );
  }
}

// Sentinel for nullable copyWith params so null can be passed explicitly.
const Object _sentinel = Object();
