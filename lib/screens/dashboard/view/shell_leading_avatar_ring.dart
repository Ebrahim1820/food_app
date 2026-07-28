import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// Wraps the AppBar's leading profile avatar with consistent edge padding
/// and a subtle gold ring, so `DashboardScreen`/`MainNavigationScreen`/
/// `BusinessDashboardScreen` don't each hand-roll the same decoration.
///
/// The AppBar's `leading` slot has a *tight* (exact) width constraint —
/// [AppBar.leadingWidth], 56 by default — but only a loose height, so a
/// plain sized `Container` here would get squashed into a non-square box
/// and its circular decoration would render as an oval. Wrapping the fixed
/// square [SizedBox] in [Center] lets it size independently of that outer
/// tight width instead of being stretched to match it.
class ShellLeadingAvatarRing extends StatelessWidget {
  const ShellLeadingAvatarRing({
    super.key,
    required this.child,
    this.diameter = 36,
    this.showStatusBadge = true,
  });

  final Widget child;

  /// Outer ring diameter — should be the avatar's own `size` plus 2x the
  /// ring's internal padding (2px each side).
  final double diameter;

  /// Small green "online" dot at the bottom-right of the ring, per spec.
  final bool showStatusBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 2),
      child: Center(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.activeTabGold, width: 1.5),
                ),
                child: Padding(padding: const EdgeInsets.all(2), child: child),
              ),
              if (showStatusBadge)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.shellBackground, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
