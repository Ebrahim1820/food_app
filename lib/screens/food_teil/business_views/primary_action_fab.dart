import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// A full-width sticky action button designed for the
/// [Scaffold.bottomNavigationBar] slot.
///
/// Matches the style of the "Invite" FAB on the Team Members screen:
/// primary-green, pill-shaped, icon on the left, bold label, loading spinner.
///
/// Usage:
/// ```dart
/// bottomNavigationBar: Obx(() => PrimaryActionFab(
///   label: 'Preview & Publish',
///   icon: Icons.visibility_outlined,
///   isLoading: controller.isSaving.value,
///   onPressed: controller.isSaving.value ? null : _onSubmit,
/// )),
/// ```
class PrimaryActionFab extends StatelessWidget {
  const PrimaryActionFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Defaults to [AppColors.primary] when null.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: onPressed == null ? AppColors.gray300 : bg,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: bg.withValues(alpha: 0.35),
            ),
            onPressed: onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
