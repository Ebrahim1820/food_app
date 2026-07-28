import 'package:flutter/material.dart';
import 'package:food_app/controllers/admin_controller.dart';
import 'package:food_app/models/business_partner_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminPartnerDetailScreen extends StatelessWidget {
  final BusinessPartnerModel partner;
  final int userCount;
  final AdminController ctrl;

  const AdminPartnerDetailScreen({
    super.key,
    required this.partner,
    required this.userCount,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final kycColor = _kycColor(partner.kycStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2B4A), Color(0xFF2D4270)],
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
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              _initials(partner.businessName),
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
                              Text(
                                partner.businessName,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (partner.city.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 13,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${partner.city}${partner.zipCode.isNotEmpty ? ', ${partner.zipCode}' : ''}',
                                      style: TextStyle(
                                        color: AppColors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              _KycBadge(
                                label: partner.kycStatus.isEmpty
                                    ? 'N/A'
                                    : partner.kycStatus,
                                color: kycColor,
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
                // Stats row
                _StatsRow(partner: partner, userCount: userCount),
                const SizedBox(height: 20),

                // Business info
                _SectionCard(
                  title: 'Business Information',
                  icon: Icons.business_rounded,
                  children: [
                    if (partner.ownerName.isNotEmpty)
                      _InfoRow(
                        Icons.person_rounded,
                        'Owner',
                        partner.ownerName,
                      ),
                    if (partner.registrationBusinessNumber.isNotEmpty)
                      _InfoRow(
                        Icons.numbers_rounded,
                        'Reg. No.',
                        partner.registrationBusinessNumber,
                      ),
                    if (partner.taxNumber.isNotEmpty)
                      _InfoRow(
                        Icons.receipt_rounded,
                        'Tax No.',
                        partner.taxNumber,
                      ),
                    if (partner.createdAt.isNotEmpty)
                      _InfoRow(
                        Icons.calendar_today_rounded,
                        'Joined',
                        _formatDate(partner.createdAt),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address
                if (partner.street.isNotEmpty)
                  _SectionCard(
                    title: 'Address',
                    icon: Icons.location_on_rounded,
                    children: [
                      _InfoRow(Icons.map_rounded, 'Street', partner.street),
                      _InfoRow(
                        Icons.location_city_rounded,
                        'City',
                        partner.city,
                      ),
                      if (partner.zipCode.isNotEmpty)
                        _InfoRow(
                          Icons.markunread_mailbox_rounded,
                          'Postal Code',
                          partner.zipCode,
                        ),
                    ],
                  ),
                if (partner.street.isNotEmpty) const SizedBox(height: 16),

                // Financial info
                _SectionCard(
                  title: 'Financial Details',
                  icon: Icons.account_balance_rounded,
                  children: [
                    _InfoRow(
                      Icons.local_shipping_rounded,
                      'Delivery Fee',
                      CurrencyFormatter.format(
                        double.tryParse(partner.deliveryFee.toString()) ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Recent orders from this partner
                _PartnerOrdersSection(partner: partner, ctrl: ctrl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Color _kycColor(String status) => switch (status.toLowerCase()) {
    'verified' || 'approved' => AppColors.successDark,
    'pending' || 'in_review' || 'under_review' => AppColors.warning,
    _ => AppColors.error,
  };

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final BusinessPartnerModel partner;
  final int userCount;
  const _StatsRow({required this.partner, required this.userCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Rating',
            value: partner.rating > 0 ? partner.rating.toStringAsFixed(1) : '—',
            icon: Icons.star_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Staff',
            value: '$userCount',
            icon: Icons.people_rounded,
            color: AppColors.infoDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Del. Fee',
            value: CurrencyFormatter.format(
              double.tryParse(partner.deliveryFee.toString()) ?? 0,
            ),
            icon: Icons.local_shipping_rounded,
            color: AppColors.primary,
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
              fontSize: 16,
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

class _KycBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _KycBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Partner Orders Section ────────────────────────────────────────────────────

class _PartnerOrdersSection extends StatelessWidget {
  final BusinessPartnerModel partner;
  final AdminController ctrl;
  const _PartnerOrdersSection({required this.partner, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = ctrl.orders
          .where((o) => o.businessPartner.id == partner.id)
          .take(5)
          .toList();

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
                '${ctrl.orders.where((o) => o.businessPartner.id == partner.id).length} total',
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
    });
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
                  '#${order.id}  ·  ${order.user?.firstName ?? '?'} ${order.user?.lastName ?? ''}',
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
