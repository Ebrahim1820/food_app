import 'package:flutter/material.dart';

/// A discrete permission a team member can hold within a business partner.
/// Each permission maps 1-to-1 with a section of the business dashboard.
/// The backend should store these as an array/set on the user or a join table.
enum TeamPermission {
  manageOffers(
    'Manage Offers',
    'Create, edit and remove food offers',
    Icons.restaurant_menu_outlined,
  ),
  manageOrders(
    'Manage Orders',
    'View and update order status',
    Icons.receipt_long_outlined,
  ),
  viewEarnings(
    'View Earnings',
    'See revenue and payout reports',
    Icons.account_balance_wallet_outlined,
  ),
  viewAnalytics(
    'View Analytics',
    'Access performance and sales charts',
    Icons.bar_chart_outlined,
  ),
  manageTeam(
    'Manage Team',
    'Invite and remove team members',
    Icons.group_outlined,
  );

  const TeamPermission(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;

  /// Converts to/from the string key stored in the backend payload.
  String get apiKey => name; // e.g. "manageOffers"

  static TeamPermission? fromApiKey(String key) =>
      TeamPermission.values.where((p) => p.apiKey == key).firstOrNull;
}

enum MemberStatus { active, pending, suspended }

class TeamMemberModel {
  const TeamMemberModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isOwner,
    required this.status,
    required this.permissions,
    this.role = '',
    this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final bool isOwner;
  final MemberStatus status;

  /// The set of permissions this member holds. Empty means read-only/no access.
  final Set<TeamPermission> permissions;

  /// A human-readable job title set by the owner (e.g. "Manager", "Staff").
  final String role;

  final DateTime? joinedAt;

  /// Two-letter initials for the avatar.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  TeamMemberModel copyWith({
    String? role,
    MemberStatus? status,
    Set<TeamPermission>? permissions,
  }) => TeamMemberModel(
    id: id,
    name: name,
    email: email,
    isOwner: isOwner,
    status: status ?? this.status,
    permissions: permissions ?? this.permissions,
    role: role ?? this.role,
    joinedAt: joinedAt,
  );

  /// Deserialise from the backend JSON shape.
  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = (json['permissions'] as List<dynamic>?) ?? [];
    final perms = rawPerms
        .map((k) => TeamPermission.fromApiKey(k as String))
        .whereType<TeamPermission>()
        .toSet();

    return TeamMemberModel(
      id: json['id']?.toString() ?? '',
      name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      email: json['email'] as String? ?? '',
      isOwner:
          json['isOwner'] as bool? ??
          ((json['roles'] as List<dynamic>?)?.contains(
                'ROLE_BUSINESS_PARTNER',
              ) ??
              false),
      status: switch ((json['status'] as String?)) {
        'pending' => MemberStatus.pending,
        'suspended' => MemberStatus.suspended,
        _ => MemberStatus.active,
      },
      permissions: perms,
      role: json['role'] as String? ?? '',
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String)
          : null,
    );
  }

  /// Serialise to the shape the backend expects on PATCH/POST.
  Map<String, dynamic> toJson() => {
    'permissions': permissions.map((p) => p.apiKey).toList(),
    'role': role,
  };
}
