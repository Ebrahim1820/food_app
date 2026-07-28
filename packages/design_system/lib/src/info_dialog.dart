import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// A generic single-button informational dialog.
///
/// Usage:
///   await InfoDialog.show(
///     context,
///     icon: Icons.storefront_outlined,
///     iconColor: AppColors.warningDark,
///     title: 'Restaurant Closed',
///     body: 'This restaurant is currently not accepting orders.',
///     buttonLabel: 'Got It',       // optional, defaults to 'OK'
///   );
class InfoDialog extends StatelessWidget {
  const InfoDialog({
    super.key,
    required this.icon,
    this.iconColor = AppColors.warningDark,
    required this.title,
    required this.body,
    this.buttonLabel = 'OK',
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String buttonLabel;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    Color iconColor = AppColors.warningDark,
    required String title,
    required String body,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => InfoDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        body: body,
        buttonLabel: buttonLabel,
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
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
