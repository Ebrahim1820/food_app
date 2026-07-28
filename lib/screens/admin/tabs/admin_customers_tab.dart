import 'package:flutter/material.dart';
import 'package:food_app/controllers/admin_controller.dart';
import 'package:food_app/models/user_model.dart';
import 'package:food_app/screens/admin/admin_customer_detail_screen.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/filter_chip_widget.dart';
import 'package:get/get.dart';

class AdminCustomersTab extends StatelessWidget {
  final AdminController ctrl;
  const AdminCustomersTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchBar(
          hint: 'Search by name or email…',
          onChanged: (v) => ctrl.customersSearch.value = v,
        ),
        _CustomerFilterRow(ctrl: ctrl),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: ctrl.refreshCustomers,
            child: Obx(() {
              final list = ctrl.filteredCustomers;
              if (ctrl.isLoading.value && list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return _EmptyState(
                  icon: Icons.people_outline_rounded,
                  message: 'No customers found',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: list.length,
                itemBuilder: (_, i) => _CustomerCard(
                  user: list[i],
                  onTap: () => Get.to(
                    () => AdminCustomerDetailScreen(user: list[i], ctrl: ctrl),
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

// ── Customer Card ─────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _CustomerCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = '${user.firstName} ${user.lastName}'.trim();
    final initials = _initials(user.firstName, user.lastName);
    final isBP = user.roles.contains('ROLE_BUSINESS_PARTNER');
    final isAdmin = user.roles.contains('ROLE_ADMIN');
    final accentColor = isAdmin
        ? AppColors.purple
        : isBP
        ? AppColors.infoDark
        : AppColors.primary;
    final accentBg = isAdmin
        ? AppColors.purpleLight
        : isBP
        ? AppColors.infoLight
        : AppColors.primaryLight;
    final roleLabel = isAdmin
        ? 'Admin'
        : isBP
        ? 'Partner'
        : 'Customer';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accentBg,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (user.isVerified)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.successDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? user.email : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (user.createdAt != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(user.createdAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}';
  }
}

// ── Customer Filter Row ───────────────────────────────────────────────────────

class _CustomerFilterRow extends StatelessWidget {
  final AdminController ctrl;
  const _CustomerFilterRow({required this.ctrl});

  static const _roles = [
    ('all', 'All'),
    ('customer', 'Customer'),
    ('partner', 'Partner'),
    ('admin', 'Admin'),
  ];

  static const _verified = [
    ('all', 'All'),
    ('verified', 'Verified'),
    ('unverified', 'Unverified'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentRole = ctrl.customersRoleFilter.value;
      final currentVerified = ctrl.customersVerifiedFilter.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role filter
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _roles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _roles[i];
                return FilterChipWidget(
                  label: label,
                  selected: currentRole == value,
                  onTap: () => ctrl.customersRoleFilter.value = value,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Verified filter
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _verified.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _verified[i];
                return FilterChipWidget(
                  label: label,
                  selected: currentVerified == value,
                  onTap: () => ctrl.customersVerifiedFilter.value = value,
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      );
    });
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

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
