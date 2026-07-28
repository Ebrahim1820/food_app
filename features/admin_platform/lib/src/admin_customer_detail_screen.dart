import 'package:flutter/material.dart';
import 'package:admin_platform/admin_platform.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:models/models.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:intl/intl.dart';

class AdminCustomerDetailScreen extends StatelessWidget {
  final UserModel user;
  final AdminController ctrl;

  const AdminCustomerDetailScreen({
    super.key,
    required this.user,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${user.firstName} ${user.lastName}'.trim();
    final initials = _initials(user.firstName, user.lastName);
    final accentColor = _accentColor(user.roles);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: accentColor,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name.isEmpty ? user.email : name,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: AppColors.white,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: AppColors.white.withValues(
                                    alpha: 0.75,
                                  ),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: _roleChips(user.roles),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick stats
                _QuickStats(user: user, ctrl: ctrl),
                const SizedBox(height: 20),

                // Personal info
                _SectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_rounded,
                  children: [
                    if (user.firstName.isNotEmpty)
                      _InfoRow(
                        Icons.badge_rounded,
                        'First Name',
                        user.firstName,
                      ),
                    if (user.lastName.isNotEmpty)
                      _InfoRow(
                        Icons.badge_outlined,
                        'Last Name',
                        user.lastName,
                      ),
                    _InfoRow(Icons.email_rounded, 'Email', user.email),
                    if (user.phone != null && user.phone!.isNotEmpty)
                      _InfoRow(Icons.phone_rounded, 'Phone', user.phone!),
                    _InfoRow(
                      Icons.verified_rounded,
                      'Verified',
                      user.isVerified ? 'Yes' : 'No',
                    ),
                    if (user.createdAt != null)
                      _InfoRow(
                        Icons.calendar_today_rounded,
                        'Joined',
                        _formatDate(user.createdAt!),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Roles
                _SectionCard(
                  title: 'Roles & Permissions',
                  icon: Icons.security_rounded,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.roles
                          .where(
                            (r) =>
                                !r.startsWith('default-roles') &&
                                r != 'offline_access',
                          )
                          .map((r) => _RolePill(role: r))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Business partner link
                if (user.effectiveBusinessPartnerId != null)
                  _SectionCard(
                    title: 'Business Partner',
                    icon: Icons.storefront_rounded,
                    children: [
                      _InfoRow(
                        Icons.tag_rounded,
                        'Partner ID',
                        '#${user.effectiveBusinessPartnerId}',
                      ),
                      if (user.businessPartner != null)
                        _InfoRow(
                          Icons.business_rounded,
                          'Name',
                          user.businessPartner!.businessName,
                        ),
                    ],
                  ),
                if (user.effectiveBusinessPartnerId != null)
                  const SizedBox(height: 16),

                // Address
                if (user.address != null)
                  _SectionCard(
                    title: 'Address',
                    icon: Icons.location_on_rounded,
                    children: [
                      if (user.address!.street.isNotEmpty)
                        _InfoRow(
                          Icons.map_rounded,
                          'Street',
                          user.address!.street,
                        ),
                      if (user.address!.city.isNotEmpty)
                        _InfoRow(
                          Icons.location_city_rounded,
                          'City',
                          user.address!.city,
                        ),
                      if (user.address!.postalCode.isNotEmpty)
                        _InfoRow(
                          Icons.markunread_mailbox_rounded,
                          'Postal Code',
                          user.address!.postalCode,
                        ),
                    ],
                  ),
                if (user.address != null) const SizedBox(height: 20),

                // Recent orders
                _CustomerOrdersSection(user: user, ctrl: ctrl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }

  Color _accentColor(List<String> roles) {
    if (roles.contains('ROLE_ADMIN')) return AppColors.purple;
    if (roles.contains('ROLE_BUSINESS_PARTNER')) return AppColors.infoDark;
    return AppColors.primary;
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy').format(dt);
  }

  List<Widget> _roleChips(List<String> roles) {
    return roles
        .where((r) => !r.startsWith('default-roles') && r != 'offline_access')
        .map((r) {
          final label = r.replaceAll('ROLE_', '').toLowerCase();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        })
        .toList();
  }
}

// ── Quick Stats ───────────────────────────────────────────────────────────────

class _QuickStats extends StatelessWidget {
  final UserModel user;
  final AdminController ctrl;
  const _QuickStats({required this.user, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final orderCount = ctrl.orders.where((o) => o.user?.id == user.id).length;

    final isBp = user.roles.contains('ROLE_BUSINESS_PARTNER');

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Orders',
            value: '$orderCount',
            icon: Icons.receipt_long_rounded,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Verified',
            value: user.isVerified ? 'Yes' : 'No',
            icon: Icons.verified_rounded,
            color: user.isVerified ? AppColors.successDark : AppColors.gray400,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Role',
            value: isBp ? 'Partner' : 'Customer',
            icon: isBp ? Icons.storefront_rounded : Icons.person_rounded,
            color: isBp ? AppColors.infoDark : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.gray100),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.gray400),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = role
        .replaceAll('ROLE_', '')
        .replaceAll('_', ' ')
        .toLowerCase();
    final color = role == 'ROLE_ADMIN'
        ? AppColors.purple
        : role == 'ROLE_BUSINESS_PARTNER'
        ? AppColors.infoDark
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Customer Orders Section ───────────────────────────────────────────────────

class _CustomerOrdersSection extends StatelessWidget {
  final UserModel user;
  final AdminController ctrl;
  const _CustomerOrdersSection({required this.user, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final orders = ctrl.orders
        .where((o) => o.user?.id == user.id)
        .take(5)
        .toList();
    final total = ctrl.orders.where((o) => o.user?.id == user.id).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            Text(
              '$total total',
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'No orders yet',
                style: TextStyle(color: AppColors.gray400, fontSize: 13),
              ),
            ),
          )
        else
          ...orders.map((o) => _OrderRow(order: o)),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final date = DateTime.tryParse(order.createdAt)?.toLocal();
    final dateStr = date != null ? DateFormat('MMM d, HH:mm').format(date) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id}  ·  ${order.businessPartner.businessName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                    fontSize: 13,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(double.tryParse(order.totalPrice) ?? 0),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'pending' => AppColors.warning,
    'confirmed' || 'preparing' => AppColors.infoDark,
    'ready' || 'ready_for_pickup' || 'out_for_delivery' => AppColors.cyan,
    'delivered' || 'completed' => AppColors.successDark,
    'cancelled' => AppColors.error,
    _ => AppColors.gray400,
  };
}
