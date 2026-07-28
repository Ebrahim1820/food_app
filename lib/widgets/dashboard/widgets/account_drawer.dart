// lib/features/dashboard/widgets/account_drawer.dart
//
// The account menu drawer — the single drawer for the whole customer-facing
// app, wired into AppShellScreen (the one persistent post-login shell) so
// it's never duplicated per market. Content is role-aware: business
// partners/staff get the business menu (profile, bank accounts, team, ...);
// everyone else gets the customer menu (addresses, payment methods, ...).
// BusinessDashboardScreen still owns its own separate drawer (its own
// role-based shell, out of scope here).

import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:food_app/widgets/logout_widget.dart';
import 'package:food_app/screens/food_teil/business_views/business_notifications_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_security_screen.dart';
import 'package:profile/profile.dart';
import 'package:food_app/profile_and_orders/profile/views/customer_payment_methods_screen.dart';
import 'package:food_app/profile_and_orders/profile/views/customer_settings_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class AccountDrawer extends StatelessWidget {
  const AccountDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final hasBusinessAccess =
        Get.find<AuthController>().hasBusinessDashboardAccess;
    if (!hasBusinessAccess) return const _CustomerAccountDrawer();

    // Business-capable users can explicitly switch to browsing as a plain
    // customer (see the role badge in _BusinessAccountDrawer) — reactive so
    // the drawer swaps content immediately without needing to reopen it.
    return Obx(
      () => Get.find<NavigationController>().actingAsCustomer.value
          ? const _CustomerAccountDrawer()
          : const _BusinessAccountDrawer(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer variant
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerAccountDrawer extends StatelessWidget {
  const _CustomerAccountDrawer();

  /// Only reachable when a business-capable user has explicitly switched to
  /// customer view (see AccountDrawer) — a plain customer has no business
  /// identity to switch back to, so this drawer never shows a badge for them.
  ///
  /// Picks the right business "home" via AppRoutes.businessHomeForMarkets —
  /// this used to hardcode businessDashboard (Food), which sent a
  /// Cosmetic-only business partner to a dashboard for a business they don't
  /// run instead of back to their own "My Products".
  void _switchToBusinessView() {
    Get.back(); // close the drawer — AppDrawer's role badge doesn't auto-pop
    final nav = Get.find<NavigationController>();
    nav.actingAsCustomer.value = false;
    final markets =
        Get.find<BusinessPartnerController>().partner.value?.markets ??
        const <String>[];
    Get.offNamed(AppRoutes.businessHomeForMarkets(markets));
  }

  void _handleMenu(String value) {
    switch (value) {
      case 'profile':
        // Profile is a tab inside the single persistent AppShellScreen
        // (this drawer is always opened from on top of it), not a
        // standalone route — just flip the tab index, no navigation.
        Get.find<NavigationController>().currentIndex.value = 3;
      case 'addresses':
        Get.to(() => const CustomerAddressesScreen());
      case 'payment':
        Get.to(() => const CustomerPaymentMethodsScreen());
      case 'settings':
        Get.to(() => const CustomerSettingsScreen());
      case 'help':
        Get.to(() => const CustomerHelpScreen());
      case 'about':
        Get.to(() => const CustomerAboutScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return AppDrawer(
      footer: const LogoutWidget(),
      avatarWidget: UploadableAvatar(
        initials: auth.firstName.isNotEmpty
            ? auth.firstName.characters.first.toUpperCase()
            : '?',
        imageType: 'avatar',
        userIri: auth.userId.isNotEmpty
            ? ApiEndpoints.userIri(auth.userId)
            : null,
        iriResolver: () async {
          final id = Get.find<AuthController>().userId;
          if (id.isNotEmpty) return ApiEndpoints.userIri(id);
          final kcId = await Get.find<KeycloakAuthService>().getUserId();
          return kcId != null && kcId.isNotEmpty
              ? ApiEndpoints.userIri(kcId)
              : null;
        },
        size: 52,
        canUpload: true,
        backgroundColor: AppColors.white.withValues(alpha: 0.25),
        initialsColor: AppColors.white,
      ),
      userToken: auth.accessToken.value,
      // Only shown when a business-capable user has switched to customer
      // view (see AccountDrawer) — tapping it switches back.
      roleBadge: auth.hasBusinessDashboardAccess
          ? CustomerProfileStrings.businessViewBadge
          : null,
      onRoleBadgeTap: auth.hasBusinessDashboardAccess
          ? _switchToBusinessView
          : null,
      onMenuSelected: _handleMenu,
      sections: [
        DrawerSection(
          items: [
            DrawerItem(
              icon: Icons.person_outline_rounded,
              label: CustomerProfileStrings.editProfileButton,
              value: 'profile',
            ),
          ],
        ),
        DrawerSection(
          items: [
            DrawerItem(
              icon: Icons.location_on_outlined,
              label: CustomerProfileStrings.menuAddresses,
              value: 'addresses',
              iconColor: AppColors.infoDark,
            ),
            DrawerItem(
              icon: Icons.credit_card_rounded,
              label: CustomerProfileStrings.menuPaymentMethods,
              value: 'payment',
              iconColor: AppColors.accentDark,
            ),
            DrawerItem(
              icon: Icons.settings_outlined,
              label: CustomerProfileStrings.menuSettings,
              value: 'settings',
              iconColor: AppColors.gray500,
            ),
          ],
        ),
        DrawerSection(
          items: [
            DrawerItem(
              icon: Icons.help_outline_rounded,
              label: CustomerProfileStrings.menuHelp,
              value: 'help',
              iconColor: AppColors.purple,
            ),
            DrawerItem(
              icon: Icons.info_outline_rounded,
              label: CustomerProfileStrings.menuAbout,
              value: 'about',
              iconColor: AppColors.cyan,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Business variant
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessAccountDrawer extends StatelessWidget {
  const _BusinessAccountDrawer();

  void _handleMenu(String value) {
    switch (value) {
      case 'business_profile':
        Get.to(() => const BusinessProfileScreen());
      case 'bank_account':
        Get.to(() => const BusinessBankAccountScreen());
      case 'operating_hours':
        Get.to(() => const BusinessOperatingHoursScreen());
      case 'photos_branding':
        Get.to(() => const BusinessPhotosScreen());
      case 'locations':
        Get.to(() => const BusinessAddressesScreen());
      case 'team_members':
        // Standalone route (same one BusinessSettingsScreen already links
        // to) rather than the old in-shell tab flip — TeamMembersScreen
        // renders its own back arrow when opened this way (onBack: null).
        Get.toNamed(AppRoutes.teamMembers);
      case 'push_notifications':
        Get.to(() => const BusinessNotificationsScreen());
      case 'email_alerts':
        Get.to(() => const BusinessEmailAlertsScreen());
      case 'security':
        Get.to(() => const BusinessSecurityScreen());
      case 'help':
        Get.to(() => const BusinessHelpScreen());
      case 'about':
        Get.to(() => const BusinessAboutScreen());
      case 'settings':
        Get.to(
          () => BusinessSettingsScreen(
            onOpenNotifications: () =>
                Get.to(() => const BusinessNotificationsScreen()),
            onOpenSecurity: () => Get.to(() => const BusinessSecurityScreen()),
          ),
        );
    }
  }

  /// Lets an owner/staff member browse and buy from *other* stores as a
  /// plain customer instead of always being routed back to their own
  /// business (see DashboardController.onTileTap). Already inside
  /// AppShellScreen (this drawer only renders there) — no navigation
  /// needed, just reset which market's tiles/content are showing.
  void _switchToCustomerView() {
    Get.back(); // close the drawer — AppDrawer's role badge doesn't auto-pop
    final nav = Get.find<NavigationController>();
    nav.actingAsCustomer.value = true;
    nav.activeMarket.value = null;
    nav.currentIndex.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      final bpCtrl = Get.find<BusinessPartnerController>();
      final partner = bpCtrl.partner.value;
      final initials = partner?.businessName.isNotEmpty == true
          ? partner!.businessName.characters.first.toUpperCase()
          : '?';
      return AppDrawer(
        footer: const LogoutWidget(),
        avatarWidget: UploadableAvatar(
          initials: initials,
          imageType: 'business_logo',
          partnerIri: partner?.iri,
          uploadPartnerIri: partner?.iri,
          size: 52,
          canUpload: true,
          backgroundColor: AppColors.white.withValues(alpha: 0.25),
          initialsColor: AppColors.white,
        ),
        userToken: authController.accessToken.value,
        roleBadge: authController.isBusinessPartner
            ? 'biz_drawer_ownerBadge'.tr
            : 'biz_drawer_memberBadge'.tr,
        onRoleBadgeTap: _switchToCustomerView,
        onMenuSelected: _handleMenu,
        sections: [
          DrawerSection(
            label: 'biz_drawer_sectionBusiness'.tr,
            items: [
              // The full profile PATCH (name, contact info, cash-payment
              // toggle, delivery fee) is owner-only on the backend — staff
              // only get the separate toggle-active (open/closed) switch
              // elsewhere on the dashboard. Hide the entry instead of
              // letting staff open a screen full of controls that 403.
              if (authController.isBusinessPartner)
                DrawerItem(
                  icon: Icons.store_outlined,
                  label: 'biz_drawer_businessProfile'.tr,
                  value: 'business_profile',
                ),
              // GET /business_bank_accounts is owner-only on the backend now —
              // hide the entry for staff (ROLE_MEMBER) instead of letting them
              // tap in and hit a 403.
              if (authController.isBusinessPartner)
                DrawerItem(
                  icon: Icons.account_balance_outlined,
                  label: 'biz_drawer_bankAccountsAndPayment'.tr,
                  value: 'bank_account',
                  iconColor: AppColors.accentDark,
                ),
              DrawerItem(
                icon: Icons.schedule_outlined,
                label: 'biz_drawer_operatingHours'.tr,
                value: 'operating_hours',
                iconColor: AppColors.infoDark,
              ),
              DrawerItem(
                icon: Icons.photo_camera_outlined,
                label: 'biz_drawer_photosBranding'.tr,
                value: 'photos_branding',
                iconColor: AppColors.pink,
              ),
              DrawerItem(
                icon: Icons.location_on_outlined,
                label: 'biz_drawer_locations'.tr,
                value: 'locations',
                iconColor: AppColors.error,
              ),
            ],
          ),
          if (authController.isBusinessPartner)
            DrawerSection(
              label: 'biz_drawer_sectionTeam'.tr,
              items: [
                DrawerItem(
                  icon: Icons.group_outlined,
                  label: 'biz_drawer_teamMembers'.tr,
                  value: 'team_members',
                  iconColor: AppColors.purple,
                ),
              ],
            ),
          DrawerSection(
            label: 'biz_drawer_sectionAccount'.tr,
            items: [
              DrawerItem(
                icon: Icons.settings_outlined,
                label: 'partner_settings'.tr,
                value: 'settings',
                iconColor: AppColors.gray500,
              ),
            ],
          ),
        ],
      );
    });
  }
}
