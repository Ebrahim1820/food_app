import 'package:flutter/material.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// About Screen
//
// Shows app identity (logo, name, version), legal links, social channels,
// and a "Rate us" prompt.  All purely presentational — no backend calls.
// ---------------------------------------------------------------------------

class BusinessAboutScreen extends StatelessWidget {
  const BusinessAboutScreen({super.key});

  // App version shown to the user.  Replace with PackageInfo.fromPlatform()
  // from the package_info_plus package when you want the real build number.
  static const _version = '1.0.0 (build 42)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          BusinessAboutStrings.appBarTitle,
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
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
          children: [
            // ── App identity hero ────────────────────────────────────────────
            // Large centred logo, app name and version number.
            _AppHero(),

            const SizedBox(height: 32),

            // ── Rate us card ─────────────────────────────────────────────────
            // A full-width card that opens the app store review flow.
            _RateUsCard(),

            const SizedBox(height: 24),

            // ── Legal ────────────────────────────────────────────────────────
            _SectionLabel(BusinessAboutStrings.sectionLegal),
            _AboutCard(
              children: [
                _LinkTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.infoDark,
                  title: BusinessAboutStrings.termsOfService,
                  onTap: () => AppSnackbar.success(
                    BusinessAboutStrings.termsSnackTitle,
                    BusinessAboutStrings.termsSnackBody,
                  ),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),
                _LinkTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.purple,
                  title: BusinessAboutStrings.privacyPolicy,
                  onTap: () => AppSnackbar.success(
                    BusinessAboutStrings.privacySnackTitle,
                    BusinessAboutStrings.privacySnackBody,
                  ),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),
                _LinkTile(
                  icon: Icons.gavel_outlined,
                  iconColor: AppColors.warningDark,
                  title: BusinessAboutStrings.cookiePolicy,
                  onTap: () => AppSnackbar.success(
                    BusinessAboutStrings.cookiesSnackTitle,
                    BusinessAboutStrings.cookiesSnackBody,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Follow us ────────────────────────────────────────────────────
            _SectionLabel(BusinessAboutStrings.sectionFollowUs),
            _AboutCard(
              children: [
                _LinkTile(
                  icon: Icons.camera_alt_outlined,
                  iconColor: AppColors.pink,
                  title: 'Instagram',
                  subtitle: '@perkaApp',
                  onTap: () => AppSnackbar.success(
                    'Instagram',
                    BusinessAboutStrings.openingInstagram,
                  ),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),
                _LinkTile(
                  icon: Icons.alternate_email_outlined,
                  iconColor: AppColors.infoDark,
                  title: 'Twitter / X',
                  subtitle: '@perkaApp',
                  onTap: () => AppSnackbar.success(
                    'Twitter',
                    BusinessAboutStrings.openingTwitter,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Footer ───────────────────────────────────────────────────────
            Center(
              child: Text(
                BusinessAboutStrings.copyright,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Large centred hero block: icon + app name + version
// ---------------------------------------------------------------------------
class _AppHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App icon with a gradient background — mirrors the splash screen logo
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
          child: Center(
            child: Image.asset(
              'assets/icon/perka_mark_light.png',
              width: 46,
              height: 46,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'splash_appName'.tr,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          BusinessAboutStrings.businessPartnerApp,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        // Version badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${BusinessAboutStrings.versionPrefix} ${BusinessAboutScreen._version}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Full-width "Rate Us" card with star icons
// ---------------------------------------------------------------------------
class _RateUsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppSnackbar.success(
        BusinessAboutStrings.rateUsSnackTitle,
        BusinessAboutStrings.rateUsSnackBody,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Five star icons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BusinessAboutStrings.rateUsTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BusinessAboutStrings.rateUsSub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    5,
                    (_) => const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small uppercase section label
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.gray400,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// White card wrapping a group of link tiles
// ---------------------------------------------------------------------------
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// A tappable row with icon, title, optional subtitle, and a chevron
// ---------------------------------------------------------------------------
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.gray300,
        size: 20,
      ),
    );
  }
}
