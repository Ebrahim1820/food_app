class BankAccountModel {
  final String id;
  final String businessPartnerIri;
  final String bankName;
  final String accountHolderName;
  final String iban;
  final String swiftOrBicCode;
  final String accountNumber;
  final bool isDefault;

  BankAccountModel({
    required this.id,
    required this.businessPartnerIri,
    required this.bankName,
    required this.accountHolderName,
    required this.iban,
    required this.swiftOrBicCode,
    required this.accountNumber,
    this.isDefault = false,
  });

  String get iri => '/api/business-bank-accounts/$id';

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    final rawBp = json['businessPartner'];
    return BankAccountModel(
      id: _extractId(json['@id'] ?? ''),
      businessPartnerIri: rawBp is String ? rawBp : (rawBp?['@id'] ?? ''),
      bankName: json['bankName'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      iban: json['iban'] ?? '',
      swiftOrBicCode: json['swiftOrBicCode'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      isDefault: (json['isDefault'] ?? json['default']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson({required String businessPartnerIri}) => {
    'businessPartner': businessPartnerIri,
    'bankName': bankName,
    'accountHolderName': accountHolderName,
    'iban': iban,
    'swiftOrBicCode': swiftOrBicCode,
    'accountNumber': accountNumber,
    'isDefault': isDefault,
  };

  BankAccountModel copyWith({
    String? bankName,
    String? accountHolderName,
    String? iban,
    String? swiftOrBicCode,
    String? accountNumber,
    bool? isDefault,
  }) {
    return BankAccountModel(
      id: id,
      businessPartnerIri: businessPartnerIri,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      iban: iban ?? this.iban,
      swiftOrBicCode: swiftOrBicCode ?? this.swiftOrBicCode,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  static String _extractId(String iri) => iri.split('/').last;
}
