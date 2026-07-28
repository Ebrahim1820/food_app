import 'package:flutter/material.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:profile/profile.dart';
import 'package:core/core.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class BusinessSettingsScreen extends StatelessWidget {
  const BusinessSettingsScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onOpenSecurity,
  });

  /// Both push-notification toggling and change-password live in app-level
  /// services this package can't depend on (PushNotificationService,
  /// the change-password session-clearing flow) — the app supplies the
  /// actual screens via these callbacks.
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSecurity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          'partner_settings'.tr,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.of(context).padding.bottom + 40,
          ),
          children: [
            // ── Language ──────────────────────────────────────────────────────────
            _SectionLabel(CustomerProfileStrings.sectionLanguage),
            const SizedBox(height: 8),
            const LanguageSelectorWidget(),
            const SizedBox(height: 20),

            _SectionLabel(BusinessSettingsPageStrings.sectionBusiness),
            _SettingsTile(
              icon: Icons.store_outlined,
              iconColor: AppColors.primary,
              title: BusinessSettingsPageStrings.businessProfile,
              subtitle: BusinessSettingsPageStrings.businessProfileSub,
              onTap: () => Get.to(() => const BusinessProfileScreen()),
            ),
            _SettingsTile(
              icon: Icons.schedule_outlined,
              iconColor: AppColors.infoDark,
              title: BusinessSettingsPageStrings.operatingHours,
              subtitle: BusinessSettingsPageStrings.operatingHoursSub,
              onTap: () => Get.to(() => const BusinessOperatingHoursScreen()),
            ),
            _SettingsTile(
              icon: Icons.photo_camera_outlined,
              iconColor: AppColors.purple,
              title: BusinessSettingsPageStrings.photosBranding,
              subtitle: BusinessSettingsPageStrings.photosBrandingSub,
              onTap: () => Get.to(() => const BusinessPhotosScreen()),
            ),
            _SettingsTile(
              icon: Icons.location_on_outlined,
              iconColor: AppColors.successDark,
              title: BusinessSettingsPageStrings.locations,
              subtitle: BusinessSettingsPageStrings.locationsSub,
              onTap: () => Get.to(() => const BusinessAddressesScreen()),
            ),

            const SizedBox(height: 12),
            _SectionLabel(BusinessSettingsPageStrings.sectionTeam),
            _SettingsTile(
              icon: Icons.group_outlined,
              iconColor: AppColors.successDark,
              title: BusinessSettingsPageStrings.teamMembers,
              subtitle: BusinessSettingsPageStrings.teamMembersSub,
              trailing: _CountBadge(1),
              onTap: () => Get.toNamed(AppRoutes.teamMembers),
            ),

            const SizedBox(height: 12),
            _SectionLabel(BusinessSettingsPageStrings.sectionNotifications),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.warningDark,
              title: BusinessSettingsPageStrings.pushNotifications,
              subtitle: BusinessSettingsPageStrings.pushNotificationsSub,
              onTap: onOpenNotifications,
            ),
            _SettingsTile(
              icon: Icons.email_outlined,
              iconColor: AppColors.infoDark,
              title: BusinessSettingsPageStrings.emailAlerts,
              subtitle: BusinessSettingsPageStrings.emailAlertsSub,
              onTap: () => Get.to(() => const BusinessEmailAlertsScreen()),
            ),

            const SizedBox(height: 12),
            _SectionLabel(BusinessSettingsPageStrings.sectionAccount),
            _SettingsTile(
              icon: Icons.lock_outline,
              iconColor: AppColors.gray600,
              title: BusinessSettingsPageStrings.security,
              subtitle: BusinessSettingsPageStrings.securitySub,
              onTap: onOpenSecurity,
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              iconColor: AppColors.gray600,
              title: BusinessSettingsPageStrings.helpSupport,
              onTap: () => Get.to(() => const BusinessHelpScreen()),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              iconColor: AppColors.gray600,
              title: BusinessSettingsPageStrings.about,
              onTap: () => Get.to(() => const BusinessAboutScreen()),
            ),
            _SettingsTile(
              icon: Icons.cleaning_services_outlined,
              iconColor: AppColors.primary,
              title: BusinessSettingsPageStrings.clearCache,
              subtitle: BusinessSettingsPageStrings.clearCacheSub,
              onTap: () => CacheService.confirmAndClear(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.gray400,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings tile
// ---------------------------------------------------------------------------
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppColors.white,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.navy,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(color: AppColors.gray500, fontSize: 12),
              )
            : null,
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.gray300),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member count badge shown next to Team Members tile
// ---------------------------------------------------------------------------
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.gray300),
      ],
    );
  }
}
