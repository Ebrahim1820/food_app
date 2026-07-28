import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// A selectable filter chip used in horizontal chip rows.
///
/// Animates its background between the app's primary colour (selected) and a
/// neutral grey (unselected) in 200 ms. Drop this next to [MenuChipWidget]
/// inside a [SingleChildScrollView] row to build a compact filter bar.
///
/// Example:
/// ```dart
/// FilterChipWidget(
///   label: 'Newest',
///   selected: sort == OfferSort.newest,
///   onTap: () => controller.sortOrder.value = OfferSort.newest,
/// )
/// ```
class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Text shown inside the chip.
  final String label;

  /// Whether this chip is currently active. Controls colour.
  final bool selected;

  /// Called when the user taps the chip.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.gray700,
          ),
        ),
      ),
    );
  }
}
