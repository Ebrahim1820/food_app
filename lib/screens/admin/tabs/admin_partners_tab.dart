import 'package:flutter/material.dart';
import 'package:food_app/controllers/admin_controller.dart';
import 'package:models/models.dart';
import 'package:food_app/screens/admin/admin_partner_detail_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:get/get.dart';

class AdminPartnersTab extends StatelessWidget {
  final AdminController ctrl;
  const AdminPartnersTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchBar(
          hint: 'Search by name or city…',
          onChanged: (v) => ctrl.partnersSearch.value = v,
        ),
        _KycFilterRow(ctrl: ctrl),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: ctrl.refreshPartners,
            child: Obx(() {
              final list = ctrl.filteredPartners;
              if (ctrl.isLoading.value && list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return _EmptyState(
                  icon: Icons.storefront_outlined,
                  message: 'No business partners found',
                );
              }
              final usersPerPartner = ctrl.usersPerPartner;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: list.length,
                itemBuilder: (_, i) => _PartnerCard(
                  partner: list[i],
                  userCount: usersPerPartner[list[i].id] ?? 0,
                  onTap: () => Get.to(
                    () => AdminPartnerDetailScreen(
                      partner: list[i],
                      userCount: usersPerPartner[list[i].id] ?? 0,
                      ctrl: ctrl,
                    ),
                    transition: Transition.cupertino,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Partner Card ──────────────────────────────────────────────────────────────

class _PartnerCard extends StatelessWidget {
  final BusinessPartnerModel partner;
  final int userCount;
  final VoidCallback onTap;

  const _PartnerCard({
    required this.partner,
    required this.userCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(partner.businessName);
    final kycColor = _kycColor(partner.kycStatus);
    final kycLabel = partner.kycStatus.isEmpty ? 'N/A' : partner.kycStatus;

    return MerchantListItem(
      onTap: onTap,
      avatarInitials: initials,
      avatarGradientColors: const [Color(0xFF1A2B4A), Color(0xFF243759)],
      title: partner.businessName,
      titleBadge: _KycBadge(label: kycLabel, color: kycColor),
      subtitle: Row(
        children: [
          if (partner.city.isNotEmpty) ...[
            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray400),
            const SizedBox(width: 3),
            Text(
              partner.city,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
            const SizedBox(width: 12),
          ],
          if (partner.rating > 0) ...[
            const Icon(Icons.star_rounded, size: 12, color: AppColors.accent),
            const SizedBox(width: 3),
            Text(
              partner.rating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
        ],
      ),
      footer: Row(
        children: [
          _Chip(icon: Icons.people_outline_rounded, label: '$userCount staff'),
          const SizedBox(width: 10),
          _Chip(
            icon: Icons.local_shipping_outlined,
            label: '€${partner.deliveryFee} fee',
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.gray300,
        size: 20,
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
}

// ── KYC Filter Row ────────────────────────────────────────────────────────────

class _KycFilterRow extends StatelessWidget {
  final AdminController ctrl;
  const _KycFilterRow({required this.ctrl});

  static const _filters = [
    ('all', 'All'),
    ('approved', 'Approved'),
    ('pending', 'Pending'),
    ('rejected', 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = ctrl.partnersKycFilter.value;
      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (value, label) = _filters[i];
            return FilterChipWidget(
              label: label,
              selected: current == value,
              onTap: () => ctrl.partnersKycFilter.value = value,
            );
          },
        ),
      );
    });
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _KycBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _KycBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.gray400),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.gray500),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hint, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _ctrl,
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray400),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.gray400,
          ),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.gray100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.gray400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
