// A ListTile with a coloured rounded-square icon on the left and a chevron on
// the right. Covers all navigation/action/link list tiles across customer
// screens: settings nav tiles, profile action tiles, about link tiles, and
// payment-method option tiles.

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class IconListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  /// Optional override for the title text colour (e.g. red for destructive actions).
  final Color? titleColor;

  /// Defaults to [FontWeight.w600].
  final FontWeight titleFontWeight;

  final VoidCallback onTap;

  const IconListTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.titleFontWeight = FontWeight.w600,
    required this.onTap,
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
          style: TextStyle(
            fontWeight: titleFontWeight,
            fontSize: 14,
            color: titleColor ?? AppColors.ink,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.gray300),
        onTap: onTap,
      ),
    );
  }
}
