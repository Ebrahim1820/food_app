import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:design_system/design_system.dart';

/// A horizontal scrollable filter bar that shows only the category chips
/// for which at least one offer exists in [offers].
///
/// Always includes an "All" chip first.  When [offers] spans only one
/// category (or is empty) the bar returns [SizedBox.shrink] so it doesn't
/// waste space on a single-item row.
///
/// [selectedKey] and [onSelected] use the raw API category keys
/// (e.g. 'all', 'fast_food', 'bakery') — not translated labels.
///
/// Usage:
/// ```dart
/// OfferCategoryFilterBar(
///   offers: controller.allOffers,
///   selectedKey: _selectedCategory.value,
///   onSelected: (key) => _selectedCategory.value = key,
/// )
/// ```
class OfferCategoryFilterBar extends StatelessWidget {
  const OfferCategoryFilterBar({
    super.key,
    required this.offers,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<FoodOfferModel> offers;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // Build the ordered list of unique API category keys present in offers.
    final seen = <String>{};
    final categoryKeys = <String>[];
    for (final o in offers) {
      if (o.category.isNotEmpty && seen.add(o.category)) {
        categoryKeys.add(o.category);
      }
    }

    // No point rendering a filter bar when there is only one category or none.
    if (categoryKeys.length <= 1) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(
          children: [
            // "All" chip always first.
            FilterChipWidget(
              label: FoodCategories.all,
              selected: selectedKey == 'all',
              onTap: () => onSelected('all'),
            ),
            ...categoryKeys.map((key) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChipWidget(
                  label: FoodCategories.label(key),
                  selected: selectedKey == key,
                  onTap: () => onSelected(key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
