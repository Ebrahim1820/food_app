import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// Red swipe-to-delete background rendered behind a [Dismissible] list tile.
///
/// Pass [alignment] matching the swipe direction:
/// * [Alignment.centerLeft]  → shown during a left-to-right swipe (primary).
/// * [Alignment.centerRight] → shown during a right-to-left swipe (secondary).
///
/// Example:
/// ```dart
/// Dismissible(
///   background: const DismissBackgroundWidget(),
///   secondaryBackground: const DismissBackgroundWidget(
///     alignment: Alignment.centerRight,
///   ),
///   ...
/// )
/// ```
class DismissBackgroundWidget extends StatelessWidget {
  const DismissBackgroundWidget({
    super.key,
    this.alignment = Alignment.centerLeft,
  });

  /// Controls on which side the delete icon appears.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete, color: AppColors.white),
    );
  }
}
