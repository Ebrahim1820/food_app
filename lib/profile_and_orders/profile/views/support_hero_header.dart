import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// Gradient hero header for support / info screens.
/// Automatically switches to a compact horizontal layout in landscape.
class SupportHeroHeader extends StatelessWidget {
  const SupportHeroHeader({
    super.key,
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.bottomChild,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;

  /// Only shown in portrait — landscape hides it to save space.
  final Widget? bottomChild;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // In landscape the notch/cutout sits on the sides — add safe-area insets
    // directly to our padding so the gradient bleeds full-width but the
    // content is never hidden behind the device edge.
    final notch = MediaQuery.of(context).padding;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20 + (isLandscape ? notch.left : 0),
        isLandscape ? 8 : 18,
        20 + (isLandscape ? notch.right : 0),
        isLandscape ? 10 : 24,
      ),
      child: isLandscape ? _LandscapeLayout(this) : _PortraitLayout(this),
    );
  }
}

// ── Portrait — full vertical layout ──────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout(this.w);
  final SupportHeroHeader w;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(w.icon, color: AppColors.white, size: 28),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              w.title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (w.badge != null) ...[
              const SizedBox(width: 10),
              _Badge(label: w.badge!, color: w.badgeColor ?? AppColors.success),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          w.subtitle,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.82),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (w.bottomChild != null) ...[
          const SizedBox(height: 14),
          w.bottomChild!,
        ],
      ],
    );
  }
}

// ── Landscape — compact horizontal layout ─────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout(this.w);
  final SupportHeroHeader w;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(w.icon, color: AppColors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      w.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (w.badge != null) ...[
                    const SizedBox(width: 8),
                    _Badge(
                      label: w.badge!,
                      color: w.badgeColor ?? AppColors.success,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                w.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.80),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Badge pill ────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
