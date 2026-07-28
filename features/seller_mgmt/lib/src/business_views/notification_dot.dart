import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// Small unread/attention dot overlaid on the top-right corner of [child] —
/// the same "something's new here" pattern used for iOS app icons, Slack
/// channel lists, etc. Deliberately never shows a count; if you need a
/// number, use a different widget (e.g. a pill/counter badge).
///
/// Purely presentational — pass [show] from whatever reactive source is
/// relevant at the call site (wrap the call in `Obx` if it's driven by an
/// Rx value, as most usages are).
///
/// Example:
/// ```dart
/// Obx(() => NotificationDot(
///   show: controller.hasUnread.value,
///   child: const Icon(Icons.receipt_long_outlined),
/// ))
/// ```
class NotificationDot extends StatelessWidget {
  const NotificationDot({
    super.key,
    required this.show,
    required this.child,
    this.size = 9,
    this.color = AppColors.error,
    this.borderColor = AppColors.white,
  });

  /// Whether the dot is visible right now.
  final bool show;

  /// The icon/widget the dot is overlaid on top of.
  final Widget child;

  /// Diameter of the dot in logical pixels.
  final double size;

  /// Dot fill color.
  final Color color;

  /// Ring color around the dot so it stands out against any background
  /// (icon color, selected-tab tint, etc).
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (show)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
