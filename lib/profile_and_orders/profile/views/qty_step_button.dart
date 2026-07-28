// A small square increment/decrement button used in quantity editors. Pass
// null for [onTap] to render the button in a disabled (greyed-out) state.

import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

class QtyStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const QtyStepButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.gray400,
        ),
      ),
    );
  }
}
