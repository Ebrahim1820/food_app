import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// One action button in a [UniversalAdaptiveDialog].
class DialogAction {
  const DialogAction({
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.color = AppColors.primary,
  });

  final String label;

  /// Defaults to popping the dialog when null.
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color color;
}

/// Generic single/multi-action informational dialog, following the same
/// visual conventions already established by `InfoDialog` and `ConfirmDialog`
/// (rounded 20px corners, centered icon, centered actions) but generalised to
/// an arbitrary [actions] list instead of one hardcoded button — so market
/// screens that today hand-roll their own one-off `AlertDialog` (e.g. the
/// near-identical `_showBusinessInactiveDialog` duplicated in `OfferCard`
/// and `OfferCardCompact`) can share one implementation.
class UniversalAdaptiveDialog extends StatelessWidget {
  const UniversalAdaptiveDialog({
    super.key,
    required this.icon,
    this.iconColor = AppColors.warningDark,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<DialogAction> actions;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    Color iconColor = AppColors.warningDark,
    required String title,
    required String body,
    List<DialogAction> actions = const [
      DialogAction(label: 'OK'),
    ],
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => UniversalAdaptiveDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        body: body,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(icon, size: 48, color: iconColor),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      content: Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: actions
          .map(
            (action) => action.isPrimary
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: action.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    onPressed:
                        action.onPressed ?? () => Navigator.of(context).pop(),
                    child: Text(action.label),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: action.color,
                      side: BorderSide(color: action.color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    onPressed:
                        action.onPressed ?? () => Navigator.of(context).pop(),
                    child: Text(action.label),
                  ),
          )
          .toList(),
    );
  }
}
