import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

// ── SheetHandle ───────────────────────────────────────────────────────────────

/// Drag handle shown at the top of every modal bottom sheet.
/// Use it as the first child inside the sheet's Column.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ── AddressFormField ──────────────────────────────────────────────────────────

/// Styled [TextFormField] used inside address add/edit forms.
///
/// Validates non-empty when [required] is true. [maxLength] suppresses the
/// counter text so the field stays compact. [textCapitalization] is passed
/// through for country-code fields that need ALL CAPS.
class AddressFormField extends StatelessWidget {
  const AddressFormField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

// ── AddressLabelSelector ──────────────────────────────────────────────────────

/// Row of tappable chips used to pick an address label (e.g. Home/Work/Other).
///
/// [options] is a list of `({String value, String label, IconData icon})`.
/// [selected] is the currently active value; [onChanged] fires on tap.
///
/// Used in:
///   • Customer address form  — home / work / other
///   • Business location form — main / branch / warehouse / other
class AddressLabelSelector extends StatelessWidget {
  const AddressLabelSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<({String value, String label, IconData icon})> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isActive = selected == opt.value;
        return GestureDetector(
          onTap: () => onChanged(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  opt.icon,
                  size: 14,
                  color: isActive ? AppColors.white : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
