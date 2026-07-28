// Reusable Impact Tracker widgets — shared between the customer and business
// sides. Mirrors the "meals rescued / CO2 / water / land saved" pattern Too
// Good To Go shows on Profile, styled like this app's other hero cards
// (BusinessSummaryCard: gradient + decorative circles + frosted stat strip).

import 'package:flutter/material.dart';
import 'package:food_app/constants/food/shared_customer_and_business_constants/impact_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/screens/food_teil/shared_customer_and_business_utils/impact_calculator.dart';

/// Compact, tappable hero card for embedding on the customer Profile tab or
/// the business Overview tab. Shows the headline "meals rescued" number plus
/// a small strip of CO2 / water / land mini-stats, and opens the full impact
/// screen on tap.
///
/// Usage:
/// ```dart
/// ImpactHeroCard(
///   stats: ImpactCalculator.fromOrders(orderController.orders),
///   subtitle: ImpactStrings.heroSubtitleCustomer,
///   onTap: () => Navigator.push(context, MaterialPageRoute(
///     builder: (_) => const CustomerImpactScreen(),
///   )),
/// )
/// ```
class ImpactHeroCard extends StatelessWidget {
  final ImpactStats stats;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const ImpactHeroCard({
    super.key,
    required this.stats,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.headerGradientStart],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(right: -38, top: -38, child: _circle(150, 0.08)),
              Positioned(left: -24, bottom: -30, child: _circle(100, 0.06)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ImpactStrings.heroTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    isLoading
                        ? const SizedBox(
                            height: 34,
                            width: 34,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            CurrencyFormatter.localizeDigits(
                              stats.mealsRescued.round().toString(),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _MiniStat(
                            icon: Icons.cloud_outlined,
                            value: _compact(stats.co2SavedKg),
                            label: 'kg CO₂',
                          ),
                          _miniDivider(),
                          _MiniStat(
                            icon: Icons.water_drop_outlined,
                            value: _compact(stats.waterSavedLiters),
                            label: 'L',
                          ),
                          _miniDivider(),
                          _MiniStat(
                            icon: Icons.terrain_outlined,
                            value: _compact(stats.landSavedM2),
                            label: 'm²',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _compact(double v) => CurrencyFormatter.localizeDigits(
    v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.round().toString(),
  );

  Widget _circle(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );

  Widget _miniDivider() => Container(
    width: 0.5,
    height: 30,
    color: Colors.white.withValues(alpha: 0.22),
  );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single stat card for the detailed grid on the full impact screen —
/// icon badge, big value + unit, and a label underneath.
class ImpactStatBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String label;

  const ImpactStatBlock({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

/// 2x2 grid of the four headline stat cards — meals, CO2, water, land.
class ImpactStatGrid extends StatelessWidget {
  final ImpactStats stats;

  const ImpactStatGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        icon: Icons.restaurant_rounded,
        color: AppColors.primary,
        value: CurrencyFormatter.localizeDigits(
          stats.mealsRescued.round().toString(),
        ),
        unit: '',
        label: ImpactStrings.statMeals,
      ),
      (
        icon: Icons.cloud_outlined,
        color: AppColors.infoDark,
        value: CurrencyFormatter.localizeDigits(
          stats.co2SavedKg.toStringAsFixed(1),
        ),
        unit: 'kg',
        label: ImpactStrings.statCo2,
      ),
      (
        icon: Icons.water_drop_outlined,
        color: AppColors.cyan,
        value: CurrencyFormatter.localizeDigits(
          stats.waterSavedLiters.round().toString(),
        ),
        unit: 'L',
        label: ImpactStrings.statWater,
      ),
      (
        icon: Icons.terrain_outlined,
        color: AppColors.warningDark,
        value: CurrencyFormatter.localizeDigits(
          stats.landSavedM2.toStringAsFixed(1),
        ),
        unit: 'm²',
        label: ImpactStrings.statLand,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: cards
          .map(
            (c) => ImpactStatBlock(
              icon: c.icon,
              color: c.color,
              value: c.value,
              unit: c.unit,
              label: c.label,
            ),
          )
          .toList(),
    );
  }
}

/// "What that means" section — translates CO2/water into relatable
/// everyday equivalents, the way TGTG's impact screen does.
class ImpactEquivalencesList extends StatelessWidget {
  final ImpactStats stats;

  const ImpactEquivalencesList({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        icon: Icons.park_outlined,
        color: AppColors.successDark,
        text: ImpactStrings.eqTrees(
          CurrencyFormatter.localizeDigits(
            stats.treesEquivalent.toStringAsFixed(1),
          ),
        ),
      ),
      (
        icon: Icons.shower_outlined,
        color: AppColors.cyan,
        text: ImpactStrings.eqShowers(
          CurrencyFormatter.localizeDigits(
            stats.showersEquivalent.round().toString(),
          ),
        ),
      ),
      (
        icon: Icons.directions_car_outlined,
        color: AppColors.infoDark,
        text: ImpactStrings.eqCarKm(
          CurrencyFormatter.localizeDigits(
            stats.carKmEquivalent.round().toString(),
          ),
        ),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: rows[i].color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(rows[i].icon, size: 17, color: rows[i].color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rows[i].text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Empty state shown on the full impact screen before the first rescue.
class ImpactEmptyState extends StatelessWidget {
  final String subtitle;

  const ImpactEmptyState({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            ImpactStrings.emptyTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
