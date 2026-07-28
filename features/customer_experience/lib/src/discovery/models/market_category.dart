import 'package:flutter/widgets.dart' show IconData;

/// One category pill on a customer discovery screen (e.g. "Pizza" for food,
/// "Skincare" for cosmetic). [key] must match the category identifiers the
/// backend for that market returns.
class MarketCategory {
  final String key;
  final String labelKey;
  final String emoji;
  final IconData? icon;

  const MarketCategory(this.key, this.labelKey, this.emoji, [this.icon]);
}
