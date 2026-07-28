import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:design_system/design_system.dart';

/// Shows what [CartController.revalidateAll] changed, if anything — reused
/// by both [CartScreen] (on open) and `CartCheckoutScreen` (right before
/// payment) so the message is worded identically wherever it appears.
/// No-op (returns immediately) when nothing changed.
Future<void> showCartRevalidationChanges(
  BuildContext context,
  CartRevalidationResult result,
) async {
  if (!result.hasChanges) return;

  final lines = [
    if (result.removedTitles.isNotEmpty)
      CartStrings.removedLine(result.removedTitles.join(', ')),
    if (result.adjustedTitles.isNotEmpty)
      CartStrings.adjustedLine(result.adjustedTitles.join(', ')),
  ];

  await InfoDialog.show(
    context,
    icon: Icons.info_outline_rounded,
    iconColor: AppColors.warningDark,
    title: CartStrings.updatedTitle,
    body: lines.join('\n\n'),
    buttonLabel: CartStrings.okButton,
  );
}
