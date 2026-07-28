// Customer — Settings Screen
//
// Four sections: Language (English / Farsi toggle via LocaleController),
// Notifications (push, email, promotional — local ValueNotifier toggles),
// Privacy & Security (change password, biometrics, delete account), and
// App (version info, clear cache, rate the app). All StatelessWidget; toggle
// state is held in per-widget ValueNotifiers — no StatefulWidget needed.

import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/profile/controllers/user_preferences_controller.dart';
import 'package:food_app/services/cache_service.dart';
import 'package:food_app/services/push_notification_service.dart';
import 'package:get/get.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/profile_and_orders/profile/views/icon_list_tile.dart';
import 'package:food_app/widgets/common/language_selector_widget.dart';
import 'package:food_app/profile_and_orders/profile/views/section_label.dart';
import 'package:food_app/profile_and_orders/profile/views/toggle_tile.dart';
import 'package:food_app/widgets/dialog/change_password_sheet.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          CustomerProfileStrings.settings,
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // ── Language ─────────────────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.sectionLanguage),
            const SizedBox(height: 8),
            const LanguageSelectorWidget(),

            const SizedBox(height: 20),

            // ── Notifications ─────────────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.sectionNotifications),
            const SizedBox(height: 8),
            ToggleTile(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.warningDark,
              title: CustomerProfileStrings.notifPush,
              subtitle: CustomerProfileStrings.notifPushSub,
              initialValue:
                  Get.find<PushNotificationService>().pushEnabled.value,
              onChanged: (v) {
                Get.find<PushNotificationService>()
                    .setPushEnabled(v)
                    .catchError((_) {});
              },
            ),
            Obx(() {
              final prefs = Get.find<UserPreferencesController>();
              return Column(
                children: [
                  ToggleTile(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.infoDark,
                    title: CustomerProfileStrings.notifEmail,
                    subtitle: CustomerProfileStrings.notifEmailSub,
                    initialValue: prefs.emailEnabled.value,
                    onChanged: (v) => prefs.setEmail(v).catchError((_) {}),
                  ),
                  ToggleTile(
                    icon: Icons.local_offer_outlined,
                    iconColor: AppColors.purple,
                    title: CustomerProfileStrings.notifPromo,
                    subtitle: CustomerProfileStrings.notifPromoSub,
                    initialValue: prefs.marketingEnabled.value,
                    onChanged: (v) => prefs.setMarketing(v).catchError((_) {}),
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),

            // ── Privacy & Security ────────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.sectionPrivacy),
            const SizedBox(height: 8),
            IconListTile(
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.gray600,
              title: CustomerProfileStrings.changePassword,
              subtitle: CustomerProfileStrings.changePasswordSub,
              titleFontWeight: FontWeight.w500,
              onTap: () => showChangePasswordSheet(context),
            ),
            ToggleTile(
              icon: Icons.fingerprint_rounded,
              iconColor: AppColors.successDark,
              title: CustomerProfileStrings.biometric,
              subtitle: CustomerProfileStrings.biometricSub,
              initialValue: false,
            ),
            IconListTile(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.error,
              title: CustomerProfileStrings.deleteAccount,
              subtitle: CustomerProfileStrings.deleteAccountSub,
              titleColor: AppColors.error,
              titleFontWeight: FontWeight.w500,
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // ── App ───────────────────────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.sectionApp),
            const SizedBox(height: 8),
            IconListTile(
              icon: Icons.cleaning_services_outlined,
              iconColor: AppColors.primary,
              title: CustomerProfileStrings.clearCache,
              subtitle: CustomerProfileStrings.clearCacheSub,
              titleFontWeight: FontWeight.w500,
              onTap: () => CacheService.confirmAndClear(context),
            ),
            IconListTile(
              icon: Icons.star_outline_rounded,
              iconColor: AppColors.accent,
              title: CustomerProfileStrings.rateApp,
              subtitle: CustomerProfileStrings.rateAppSub,
              titleFontWeight: FontWeight.w500,
              onTap: () {},
            ),
            _InfoTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.gray400,
              title: CustomerProfileStrings.appVersion,
              value: '1.0.0',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info tile (no interaction, shows a value) ─────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

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
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.ink,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
