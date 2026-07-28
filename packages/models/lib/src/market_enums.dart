/// Market — the top tier of the app's two-tier category model (Market → Category).
/// Mirrors `App\Enum\Market` in Symfony.
enum Market {
  food('food'),
  cosmetic('cosmetic'),
  clothes('clothes'),
  electronics('electronics'),
  homeAppliances('home_appliances'),
  autoEquipment('auto_equipment');

  const Market(this.value);

  /// Backing string value (matches PHP enum value)
  final String value;

  /// Human-readable display name for the UI (mirrors `Market::label()`)
  String get label {
    switch (this) {
      case Market.food:
        return 'Surplus Meals';
      case Market.cosmetic:
        return 'Cosmetics';
      case Market.clothes:
        return 'Clothes';
      case Market.electronics:
        return 'Electronics';
      case Market.homeAppliances:
        return 'Home Appliances';
      case Market.autoEquipment:
        return 'Auto Equipment';
    }
  }

  /// Safe deserialization from API responses
  static Market? tryFromValue(String? raw) {
    if (raw == null) return null;
    return Market.values.firstWhere(
      (m) => m.value.toLowerCase() == raw.toLowerCase(),
      orElse: () =>
          Market.food, // Or return null depending on fallback preference
    );
  }
}
