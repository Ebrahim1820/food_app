// Customer — About Screen
//
// Displays app identity (logo, tagline, version), the platform mission,
// legal links (Privacy Policy, Terms of Service, Open Source Licenses), and
// social media links. All content is static — no state required.

import 'package:flutter/material.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'icon_list_tile.dart';
import 'section_label.dart';
import 'package:get/get.dart';

class CustomerAboutScreen extends StatelessWidget {
  const CustomerAboutScreen({super.key});

  static const _version = '1.0.0';

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
          CustomerProfileStrings.aboutTitle,
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          children: [
            // ── App identity ─────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Food App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CustomerProfileStrings.aboutTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${CustomerProfileStrings.aboutVersion} $_version',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Mission ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: AppColors.successDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CustomerProfileStrings.aboutMissionTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CustomerProfileStrings.aboutMissionText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Legal links ───────────────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.aboutLegal),
            const SizedBox(height: 8),
            IconListTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: AppColors.infoDark,
              title: CustomerProfileStrings.aboutPrivacy,
              onTap: () => Get.to(() => const PrivacyPolicyScreen()),
            ),
            IconListTile(
              icon: Icons.description_outlined,
              iconColor: AppColors.gray600,
              title: CustomerProfileStrings.aboutTerms,
              onTap: () => Get.to(() => const TermsOfServiceScreen()),
            ),
            IconListTile(
              icon: Icons.code_rounded,
              iconColor: AppColors.purple,
              title: CustomerProfileStrings.aboutLicenses,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Food App',
                applicationVersion: _version,
              ),
            ),

            const SizedBox(height: 20),

            // ── Social links ──────────────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.aboutSocial),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialBtn(
                  icon: Icons.language_rounded,
                  color: AppColors.primary,
                  label: 'Web',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _SocialBtn(
                  icon: Icons.camera_alt_outlined,
                  color: AppColors.pink,
                  label: 'Instagram',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _SocialBtn(
                  icon: Icons.chat_rounded,
                  color: AppColors.infoDark,
                  label: 'Twitter',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Footer ────────────────────────────────────────────────────────
            Center(
              child: Text(
                CustomerProfileStrings.aboutMadeWith,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Social icon button ────────────────────────────────────────────────────────

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SocialBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
