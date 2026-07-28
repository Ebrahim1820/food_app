import 'package:flutter/material.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/screens/food_teil/business_views/business_about_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_email_alerts_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_help_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_notifications_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_security_screen.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('settings_title'.tr),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(SettingsPageStrings.sectionPreferences),
            const SizedBox(height: 12),
            GetBuilder<LocaleController>(
              builder: (ctrl) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LanguageTile(
                    flag: '🇬🇧',
                    name: 'English',
                    nativeName: 'English',
                    isSelected: ctrl.isEnglish,
                    onTap: ctrl.switchToEnglish,
                  ),
                  const SizedBox(height: 10),
                  _LanguageTile(
                    flag: '🇮🇷',
                    name: 'Persian',
                    nativeName: 'فارسی',
                    isSelected: ctrl.isFarsi,
                    onTap: ctrl.switchToFarsi,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(SettingsPageStrings.sectionAccountSecurity),
            const SizedBox(height: 12),
            _NavTile(
              icon: Icons.notifications_outlined,
              label: SettingsPageStrings.pushNotifications,
              onTap: () => Get.to(() => const BusinessNotificationsScreen()),
            ),
            _NavTile(
              icon: Icons.email_outlined,
              label: SettingsPageStrings.emailAlerts,
              onTap: () => Get.to(() => const BusinessEmailAlertsScreen()),
            ),
            _NavTile(
              icon: Icons.lock_outline,
              label: SettingsPageStrings.security,
              iconColor: AppColors.infoDark,
              onTap: () => Get.to(() => const BusinessSecurityScreen()),
            ),
            const SizedBox(height: 24),
            _SectionHeader(SettingsPageStrings.sectionSupport),
            const SizedBox(height: 12),
            _NavTile(
              icon: Icons.help_outline,
              label: SettingsPageStrings.helpSupport,
              onTap: () => Get.to(() => const BusinessHelpScreen()),
            ),
            _NavTile(
              icon: Icons.info_outline_rounded,
              label: SettingsPageStrings.about,
              onTap: () => Get.to(() => const BusinessAboutScreen()),
            ),
            const SizedBox(height: 24),
            _SectionHeader('settings_about'.tr),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.info_outline_rounded,
              label: 'settings_version'.tr,
              value: '1.0.0',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textMuted,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: iconColor),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 20,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.name,
    required this.nativeName,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String name;
  final String nativeName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nativeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (nativeName != name)
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
