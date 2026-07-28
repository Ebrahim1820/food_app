import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// A secondary (non-hero) live market tile, and the base visual style for a
/// greyed-out "coming soon" tile (see [enabled]).
class MarketTile extends StatelessWidget {
  const MarketTile({
    super.key,
    required this.icon,
    required this.label,
    this.roleBadge,
    this.enabled = true,
    required this.onTap,
  });

  factory MarketTile.comingSoon({
    required String marketKey,
    required String label,
    required VoidCallback onTap,
  }) => MarketTile(
    icon: marketIcon(marketKey),
    label: label,
    enabled: false,
    onTap: onTap,
  );

  final IconData icon;
  final String label;

  /// e.g. "Business" / "Customer" — omitted for coming-soon tiles.
  final String? roleBadge;

  /// Disabled tiles render muted/greyed and never navigate — only the
  /// coming-soon sheet opens.
  final bool enabled;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.gray50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled ? AppColors.border : AppColors.gray200,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? AppColors.primaryLight : AppColors.gray200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: enabled ? AppColors.primary : AppColors.gray400,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.textPrimary : AppColors.gray500,
              ),
            ),
            if (roleBadge != null) ...[
              const SizedBox(height: 6),
              Text(
                roleBadge!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else if (!enabled) ...[
              const SizedBox(height: 6),
              Text(
                'dashboard_comingSoon'.tr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
