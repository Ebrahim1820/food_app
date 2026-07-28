import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centered empty-state layout used when a list has no items to display.
///
/// Shows a large icon, a title, a subtitle, and an optional [action] widget
/// (typically a [TextButton] to clear filters or retry a request).
///
/// Example — no results after filtering:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.filter_list_off,
///   title: 'No orders match your filters',
///   subtitle: 'Try a different status or date range.',
///   action: TextButton(
///     onPressed: controller.clearFilters,
///     child: const Text('Clear filters'),
///   ),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Optional widget rendered below the subtitle — e.g. a "Clear filters"
  /// or "Retry" button. Omit for a simple informational empty state.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final iconSize = (MediaQuery.of(context).size.height * 0.09).clamp(
      40.0,
      70.0,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.gray600,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
