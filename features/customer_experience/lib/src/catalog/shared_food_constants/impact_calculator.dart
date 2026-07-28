import 'package:customer_experience/customer_experience.dart';

/// Aggregated environmental impact of a set of rescued orders.
class ImpactStats {
  final int ordersRescued;
  final double totalKgRescued;
  final double mealsRescued;
  final double co2SavedKg;
  final double waterSavedLiters;
  final double landSavedM2;

  const ImpactStats({
    this.ordersRescued = 0,
    this.totalKgRescued = 0,
    this.mealsRescued = 0,
    this.co2SavedKg = 0,
    this.waterSavedLiters = 0,
    this.landSavedM2 = 0,
  });

  bool get isEmpty => ordersRescued == 0;

  /// Roughly how many trees-for-a-year the saved CO2 is equivalent to.
  double get treesEquivalent => co2SavedKg / ImpactCalculator.co2KgPerTreeYear;

  /// Roughly how many showers the saved water is equivalent to.
  double get showersEquivalent =>
      waterSavedLiters / ImpactCalculator.waterLitersPerShower;

  /// Roughly how many car kilometres the saved CO2 is equivalent to.
  double get carKmEquivalent => co2SavedKg / ImpactCalculator.co2KgPerCarKm;

  ImpactStats operator +(ImpactStats other) => ImpactStats(
    ordersRescued: ordersRescued + other.ordersRescued,
    totalKgRescued: totalKgRescued + other.totalKgRescued,
    mealsRescued: mealsRescued + other.mealsRescued,
    co2SavedKg: co2SavedKg + other.co2SavedKg,
    waterSavedLiters: waterSavedLiters + other.waterSavedLiters,
    landSavedM2: landSavedM2 + other.landSavedM2,
  );
}

/// Turns a customer's or a business's completed orders into an environmental
/// impact estimate — "meals rescued" plus CO2/water/land saved, the same
/// headline stats Too Good To Go shows on its Profile screen.
///
/// There is no backend aggregate for this yet, so the numbers are derived
/// client-side from [OrderItemModel] data already on hand (quantity /
/// weightTotalKg). The per-kg conversion factors below are the same order of
/// magnitude as the figures widely cited in food-waste research (WRAP/FAO):
/// every kilogram of food rescued from waste avoids roughly this much
/// CO2-equivalent emissions, water use, and agricultural land use.
abstract class ImpactCalculator {
  /// Average weight of one rescued "meal" — used to convert piece-counted
  /// items (no weightTotalKg) into an equivalent kg figure.
  static const double kgPerMeal = 0.4;

  static const double co2KgPerKgFood = 2.5;
  static const double waterLitersPerKgFood = 1000;
  static const double landM2PerKgFood = 1.5;

  static const double co2KgPerTreeYear = 21;
  static const double waterLitersPerShower = 65;
  static const double co2KgPerCarKm = 0.12;

  static bool isRescued(String status) =>
      status == 'completed' || status == 'delivered';

  static ImpactStats fromOrders(Iterable<OrderModel> orders) {
    var totalKg = 0.0;
    var rescueCount = 0;

    for (final order in orders) {
      if (!isRescued(order.status)) continue;
      rescueCount++;
      for (final item in order.orderItems) {
        totalKg += item.weightTotalKg ?? (kgPerMeal * item.quantity);
      }
    }

    return ImpactStats(
      ordersRescued: rescueCount,
      totalKgRescued: totalKg,
      mealsRescued: totalKg / kgPerMeal,
      co2SavedKg: totalKg * co2KgPerKgFood,
      waterSavedLiters: totalKg * waterLitersPerKgFood,
      landSavedM2: totalKg * landM2PerKgFood,
    );
  }
}
