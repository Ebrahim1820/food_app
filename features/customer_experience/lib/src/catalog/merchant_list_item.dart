import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// A compact, tappable row for browsing/listing businesses — avatar (initials
/// or a custom widget), name + optional status badge, an optional subtitle
/// line (location/rating/etc.), and an optional footer row (stat chips),
/// ending in a chevron. Fully generic (no model coupling) so any market's
/// "browse businesses" screen — or an admin/staff list like
/// `AdminPartnersTab`'s partner rows — can share one layout instead of each
/// hand-rolling its own card.
///
/// Example:
/// ```dart
/// MerchantListItem(
///   avatarInitials: 'JD',
///   title: partner.businessName,
///   titleBadge: _KycBadge(label: kycLabel, color: kycColor),
///   subtitle: Row(children: [Icon(Icons.location_on_rounded), Text(city)]),
///   onTap: () => Get.to(() => PartnerDetailScreen(partner: partner)),
/// )
/// ```
class MerchantListItem extends StatelessWidget {
  const MerchantListItem({
    super.key,
    required this.title,
    this.avatarInitials,
    this.avatarWidget,
    this.avatarGradientColors,
    this.titleBadge,
    this.subtitle,
    this.footer,
    this.trailing,
    this.onTap,
  }) : assert(
         avatarWidget != null || avatarInitials != null,
         'Provide either avatarWidget or avatarInitials',
       );

  final String title;

  /// Rendered inside the default gradient circle avatar. Ignored if
  /// [avatarWidget] is provided.
  final String? avatarInitials;

  /// Overrides the default initials-circle avatar entirely (e.g. a real
  /// business photo/logo widget).
  final Widget? avatarWidget;

  /// Gradient for the default initials avatar. Defaults to the shell's
  /// locked indigo (a neutral choice — pass a market's own accent via
  /// `marketAccent(key)` for market-scoped lists).
  final List<Color>? avatarGradientColors;

  /// Small badge next to [title] (status/KYC/open-closed/...).
  final Widget? titleBadge;

  /// Second row under the title (location, rating, ...).
  final Widget? subtitle;

  /// Third row — typically a row of small stat chips.
  final Widget? footer;

  /// Rendered at the far right (e.g. a chevron icon). Null renders nothing.
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradientColors =
        avatarGradientColors ??
        const [AppColors.shellBackground, AppColors.shellBackground];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              avatarWidget ??
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        avatarInitials!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.navy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (titleBadge != null) ...[
                          const SizedBox(width: 8),
                          titleBadge!,
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      subtitle!,
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 8),
                      footer!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
