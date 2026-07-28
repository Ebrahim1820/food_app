import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/greeting_header.dart';
import 'package:food_app/widgets/logout_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

/// A single tappable row in the drawer menu.
class DrawerItem {
  const DrawerItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Tint applied to the icon and its background pill.
  /// Defaults to [AppColors.primary] when null.
  final Color? iconColor;

  /// Optional short text shown as a pill on the right (e.g. "3" for a count).
  final String? badge;
}

/// A labelled group of [DrawerItem]s.
class DrawerSection {
  const DrawerSection({this.label, required this.items});

  /// Section header text (all-caps). Pass null to omit the header.
  final String? label;
  final List<DrawerItem> items;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppDrawer
// ─────────────────────────────────────────────────────────────────────────────

/// Shared slide-in drawer for both the customer and business dashboards.
///
/// Common chrome (gradient header, greeting, avatar ring, logout footer) is
/// built here. Role-specific content is supplied via [sections].
///
/// RTL handling lives in the parent Scaffold — this widget is direction-agnostic.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.avatarWidget,
    required this.userToken,
    required this.sections,
    required this.onMenuSelected,
    this.roleBadge,
    this.onRoleBadgeTap,
  });

  /// Built by the caller so customer vs business can pass different
  /// [UploadableAvatar] configurations (different imageType / IRI).
  final Widget avatarWidget;

  /// Decoded access-token string forwarded to [GreetingHeader].
  final String? userToken;

  /// Optional pill shown below the greeting, e.g. "Business Owner".
  final String? roleBadge;

  /// When set, the role badge becomes tappable (with a swap icon) — used to
  /// let a business partner/staff member switch to the customer marketplace
  /// and back without losing their business account.
  final VoidCallback? onRoleBadgeTap;

  /// Grouped menu sections rendered top-to-bottom.
  final List<DrawerSection> sections;

  /// Fired when the user taps any menu item; receives [DrawerItem.value].
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      width: screenWidth * 0.72,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              avatarWidget: avatarWidget,
              userToken: userToken,
              roleBadge: roleBadge,
              onRoleBadgeTap: onRoleBadgeTap,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                children: [
                  for (final section in sections) ...[
                    if (section.label != null) _SectionLabel(section.label!),
                    for (final item in section.items)
                      _DrawerTile(item: item, onMenuSelected: onMenuSelected),
                  ],
                ],
              ),
            ),
            _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.avatarWidget,
    required this.userToken,
    this.roleBadge,
    this.onRoleBadgeTap,
  });

  final Widget avatarWidget;
  final String? userToken;
  final String? roleBadge;
  final VoidCallback? onRoleBadgeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with a white glass ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: avatarWidget,
          ),
          const SizedBox(height: 14),

          // Greeting
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              child: GreetingHeader(token: userToken),
            ),
          ),

          // Role badge pill. Tappable (with a swap icon) when
          // [onRoleBadgeTap] is set, letting the user switch between the
          // business and customer marketplace without losing their account.
          if (roleBadge != null) ...[
            const SizedBox(height: 8),
            Material(
              color: AppColors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onRoleBadgeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        roleBadge!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (onRoleBadgeTap != null) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.sync_alt_rounded,
                          size: 13,
                          color: AppColors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu tile
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.item, required this.onMenuSelected});

  final DrawerItem item;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final color = item.iconColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            onMenuSelected(item.value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                // Icon in a soft tinted pill
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: color, size: 20),
                ),
                const SizedBox(width: 13),

                // Label
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray800,
                    ),
                  ),
                ),

                // Badge or chevron
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gray300,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, indent: 16, endIndent: 16),
        const LogoutWidget(),
        const SizedBox(height: 8),
      ],
    );
  }
}
