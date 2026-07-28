import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// A small pill showing a market's icon + name in its brand accent colour —
/// reads [marketIcon]/[marketAccent]/[marketLabel] (dashboard_icons.dart /
/// market_colors.dart) so every "which market is this" badge across the app
/// (Dashboard tiles, admin partner rows, order rows, ...) stays visually and
/// semantically in sync instead of each screen re-deriving its own colour.
///
/// Example:
/// ```dart
/// MarketCategoryBadge(marketKey: market.key, label: market.label)
/// ```
class MarketCategoryBadge extends StatelessWidget {
  const MarketCategoryBadge({
    super.key,
    required this.marketKey,
    this.labelOverride,
  });

  /// Backend market key ('food' / 'cosmetic' / 'clothes' / ...).
  final String marketKey;

  /// Overrides the localized [marketLabel] lookup — pass the raw backend
  /// label for an unrecognised market key so it still shows *something*
  /// meaningful instead of falling back to just the key.
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final color = marketAccentColor(marketKey);
    final label = marketLabel(marketKey, labelOverride ?? marketKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(marketIcon(marketKey), size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
