// Customer — Profile Screen (tab view)
//
// The profile tab the user sees in the bottom navigation. Shows a header card
// with avatar, name, and edit-profile shortcut; three stats (orders, favourites,
// saved); a grid of quick-action tiles that each navigate to their own screen;
// and a logout button at the bottom. Each section navigates to a dedicated
// sub-screen — no content is duplicated here.

import 'package:flutter/material.dart';
import 'package:auth/auth.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:profile/profile.dart';
import 'package:food_app/profile_and_orders/profile/views/customer_impact_screen.dart';
import 'package:food_app/profile_and_orders/profile/views/customer_payment_methods_screen.dart';
import 'package:food_app/profile_and_orders/profile/views/customer_settings_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/widgets/logout_widget.dart';
import 'package:get/get.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final fav = Get.find<FavoritesOfferController>();
    final orders = Get.find<OrderController>(); // food orders
    // final cosmeticOrderController =
    //     Get.find<ProductOrderController>(); // cosmetics orders

    // final String totalOrders =
    //     (orders.totalOrders.value + cosmeticOrderController.orders.length)
    //         .toString();

    /// Combines Food + Cosmetic orders for the Dashboard's "all markets"
    /// Orders tab (index 2, activeMarket == null) — see its doc comment.
    /// Food's and Cosmetic's own Orders screens don't use this at all.

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header card ──────────────────────────────────────────────
              _HeaderCard(auth: auth),
              const SizedBox(height: 16),

              // ── Stats row ────────────────────────────────────────────────
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: CurrencyFormatter.localizeDigits(
                          orders.totalOrders.value.toString(),
                        ),
                        label: CustomerProfileStrings.statOrders,
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: CurrencyFormatter.localizeDigits(
                          fav.favoriteIds.length.toString(),
                        ),
                        label: CustomerProfileStrings.statFavorites,
                        icon: Icons.favorite_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: CurrencyFormatter.format(45),
                        label: CustomerProfileStrings.statSaved,
                        icon: Icons.savings_rounded,
                        color: AppColors.successDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Impact tracker ───────────────────────────────────────────
              Obx(
                () => ImpactHeroCard(
                  stats: ImpactCalculator.fromOrders(orders.orders),
                  subtitle: ImpactStrings.heroSubtitleCustomer,
                  isLoading: orders.isLoading.value && orders.orders.isEmpty,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomerImpactScreen(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick actions ────────────────────────────────────────────
              Text(
                CustomerProfileStrings.quickActions,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.gray400,
                ),
              ),
              const SizedBox(height: 10),
              IconListTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.primary,
                title: CustomerProfileStrings.editProfileButton,
                subtitle: CustomerProfileStrings.subEditProfile,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerEditProfileScreen(),
                  ),
                ),
              ),
              IconListTile(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.infoDark,
                title: CustomerProfileStrings.menuAddresses,
                subtitle: CustomerProfileStrings.subAddresses,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerAddressesScreen(),
                  ),
                ),
              ),
              IconListTile(
                icon: Icons.credit_card_rounded,
                iconColor: AppColors.successDark,
                title: CustomerProfileStrings.menuPaymentMethods,
                subtitle: CustomerProfileStrings.subPaymentMethods,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerPaymentMethodsScreen(),
                  ),
                ),
              ),
              IconListTile(
                icon: Icons.settings_outlined,
                iconColor: AppColors.warningDark,
                title: CustomerProfileStrings.menuSettings,
                subtitle: CustomerProfileStrings.subSettings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerSettingsScreen(),
                  ),
                ),
              ),
              IconListTile(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.purple,
                title: CustomerProfileStrings.supportHelpCenter,
                subtitle: CustomerProfileStrings.subHelp,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomerHelpScreen()),
                ),
              ),
              IconListTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.gray500,
                title: CustomerProfileStrings.supportAbout,
                subtitle: CustomerProfileStrings.subAbout,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerAboutScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Logout ───────────────────────────────────────────────────
              const LogoutWidget(isFullColorButton: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final AuthController auth;
  const _HeaderCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CustomerEditProfileScreen(),
              ),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
