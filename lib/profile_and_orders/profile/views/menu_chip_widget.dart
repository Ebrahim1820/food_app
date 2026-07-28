import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// A chip that opens a [PopupMenuButton] of options when tapped.
///
/// Highlights in the primary colour when a non-default option is active and
/// renders a checkmark next to the currently selected value in the menu.
/// Designed to live alongside [FilterChipWidget] inside a
/// [SingleChildScrollView] row.
///
/// The widget is generic so any type `T` can be used as the option type — an
/// enum, a String, a domain model, etc.
///
/// Example:
/// ```dart
/// MenuChipWidget<CustomerOrderStatusFilter>(
///   label: statusActive ? controller.statusFilter.value.label : 'Status',
///   isActive: statusActive,
///   value: controller.statusFilter.value,
///   options: CustomerOrderStatusFilter.values,
///   labelOf: (s) => s.label,
///   onSelected: (v) => controller.statusFilter.value = v,
/// )
/// ```
class MenuChipWidget<T> extends StatelessWidget {
  const MenuChipWidget({
    super.key,
    required this.label,
    required this.isActive,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onSelected,
  });

  /// Text shown on the chip; typically the selected option's label when active
  /// or a generic placeholder (e.g. "Status") when inactive.
  final String label;

  /// Whether a non-default option is currently selected. Controls colour.
  final bool isActive;

  /// The currently selected value. Used to render a checkmark in the menu.
  final T value;

  /// All available options shown in the popup menu.
  final List<T> options;

  /// Converts an option to its human-readable label.
  final String Function(T) labelOf;

  /// Called when the user picks an option from the menu.
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      onSelected: onSelected,
      itemBuilder: (_) => options
          .map(
            (opt) => PopupMenuItem<T>(
              value: opt,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labelOf(opt),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  // Checkmark indicates the currently active option.
                  if (opt == value)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.gray700,
              ),
            ),
            const SizedBox(width: 2),
            // Down-arrow indicator that this chip opens a menu.
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: isActive ? AppColors.white : AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }
}
