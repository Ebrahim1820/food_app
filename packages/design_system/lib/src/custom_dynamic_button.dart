import 'package:flutter/material.dart';
import 'app_colors.dart';

enum CustomButtonVariant { filled, outlined, text }

/// Generic, parameter-driven button so market screens don't each hand-roll
/// their own `ElevatedButton.styleFrom(...)` — wraps Flutter's own
/// Filled/Outlined/TextButton rather than reimplementing button rendering.
class CustomDynamicButton extends StatelessWidget {
  const CustomDynamicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CustomButtonVariant.filled,
    this.accentColor = AppColors.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius = 12,
  });

  final String label;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final Color accentColor;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == CustomButtonVariant.filled
                  ? AppColors.white
                  : accentColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final Widget button = switch (variant) {
      CustomButtonVariant.filled => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.white,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        child: child,
      ),
      CustomButtonVariant.outlined => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        child: child,
      ),
      CustomButtonVariant.text => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        child: child,
      ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
