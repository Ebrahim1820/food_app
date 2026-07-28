import 'package:flutter/material.dart';

/// A compact icon button with a tinted rounded background.
///
/// Used for inline card actions (e.g. edit, cancel) where a full
/// [IconButton] would be too large and visually heavy. The background is
/// [color] at 10 % opacity so it complements rather than dominates the card.
///
/// Example:
/// ```dart
/// IconActionButton(
///   icon: Icons.edit_outlined,
///   color: AppColors.primary,
///   onTap: () => Get.to(() => CustomerEditOrderScreen(order: order)),
/// )
/// ```
class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;

  /// Tint colour used for both the icon and the background fill.
  final Color color;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
