// ignore_for_file: public_member_api_docs

/// Represents an authenticated user.
/// role: 'customer' | 'business' | 'admin'
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        isVerified: (json['verified'] as bool?) ?? false,
      );

  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool isVerified;

  bool get isBusinessPartner => role == 'business';
  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'verified': isVerified,
      };

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: $role)';
}
