// lib/widgets/common/confirm_dialog.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

// ---------------------------------------------------------------------------
// ConfirmDialog — reusable destructive-action confirmation dialog.
//
// Usage:
//   final ok = await ConfirmDialog.show(
//     context,
//     icon: Icons.delete_forever_rounded,
//     title: 'Delete Offer?',
//     subtitle: '"Surprise Bakery Bag"',      // optional — highlighted in primary
//     body: 'This cannot be undone.',
//     confirmLabel: 'Yes, Delete',
//     cancelLabel: 'Keep Offer',              // optional, defaults to 'Cancel'
//   );
//   if (ok == true) { /* proceed */ }
//
// The icon, confirm button, and icon circle all use [dangerColor] (default:
// AppColors.error) so a warning-level dialog (e.g. cancel-not-delete) can
// pass AppColors.warningDark instead.
// ---------------------------------------------------------------------------

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.body,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.dangerColor = AppColors.error,
    this.dangerLightColor = AppColors.errorLight,
  });

  final IconData icon;
  final String title;

  /// Optional short text shown in primary colour just below the title —
  /// use it to show the name of the thing being deleted.
  final String? subtitle;

  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final Color dangerColor;
  final Color dangerLightColor;

  // ── Static helper — the only entry point callers should use ──────────────

  static Future<bool?> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String body,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    Color dangerColor = AppColors.error,
    Color dangerLightColor = AppColors.errorLight,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      builder: (_) => ConfirmDialog(
        icon: icon,
        title: title,
        subtitle: subtitle,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        dangerColor: dangerColor,
        dangerLightColor: dangerLightColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coloured icon circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: dangerLightColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: dangerColor, size: 36),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),

            // Optional subtitle — name of the item being deleted
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Body text
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 28),

            // Confirm button — full width, danger colour
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: dangerColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Cancel button — full width, neutral outline
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.gray200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  cancelLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
