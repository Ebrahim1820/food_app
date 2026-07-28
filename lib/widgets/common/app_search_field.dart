import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// A consistently styled search field used across Home, Orders, and Favorites.
///
/// Shows a search icon on the left and a clear button on the right when
/// [hasText] is true. The clear button calls [onClear] so the parent can
/// reset both the [TextEditingController] and any reactive state in one place.
///
/// Example:
/// ```dart
/// AppSearchField(
///   controller: controller.searchController,
///   hint: 'Search offers…',
///   hasText: controller.searchText.value.isNotEmpty,
///   onChanged: controller.onSearchChanged,
///   onClear: () {
///     controller.searchController.clear();
///     controller.searchText.value = '';
///     controller.fetchOffers();
///   },
/// )
/// ```
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.hasText = false,
    this.onChanged,
    this.onClear,
    this.onTap,
    this.readOnly = false,
  });

  final TextEditingController controller;

  /// Placeholder text shown when the field is empty.
  final String hint;

  /// Whether there is currently text in the field. Controls clear-button
  /// visibility. Bind to a reactive bool so the button appears/disappears
  /// as the user types without rebuilding the whole screen.
  final bool hasText;

  final ValueChanged<String>? onChanged;

  /// Called when the user taps the clear (×) button.
  final VoidCallback? onClear;

  /// Called on tap — combine with [readOnly] to make this field act as a
  /// launcher into another screen's real search (e.g. the Business Dashboard
  /// AppBar's search bar jumping into the Menu tab) instead of typing inline.
  final VoidCallback? onTap;

  /// True to block typing here and rely on [onTap] instead.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.gray400,
          size: 20,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 18,
                  color: AppColors.gray400,
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: AppColors.gray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
