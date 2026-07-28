import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';

/// Shared bold section-label used above fields in the business
/// "create/edit listing" forms — was duplicated per-screen as a private
/// `_label`/`_FieldLabel` helper before being extracted here.
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Smaller, muted caption-style label used above a single field inside a
/// price-field row (e.g. Food's edit screen groups several price rows under
/// one bold [FormFieldLabel] section header, then labels each individual
/// field with this lighter caption instead of repeating the bold style).
class FormFieldCaption extends StatelessWidget {
  const FormFieldCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }
}

/// Shared `InputDecoration` for every text field in the business
/// "create/edit listing" forms.
InputDecoration productFormInputDecoration(
  String? hint, {
  String? prefix,
  String? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    prefixText: prefix,
    suffixText: suffix,
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}

/// Shared price-field validator: required + must parse to a positive
/// number. [requiredMsg]/[invalidMsg] let each market pass its own
/// translated copy.
String? validatePositiveAmount(
  String? v, {
  required String requiredMsg,
  required String invalidMsg,
}) {
  if (v == null || v.trim().isEmpty) return requiredMsg;
  if (CurrencyFormatter.parseLocalizedDouble(v) <= 0) return invalidMsg;
  return null;
}

/// Validates that [dealText] is a positive number strictly below
/// [originalText] (when [originalText] itself parses to a positive number)
/// — the "deal price must undercut the original price" rule repeated for
/// every piece/weight price-field pair across every market's form.
String? validateBelowOriginal(
  String? dealText, {
  required String originalText,
  required String requiredMsg,
  required String invalidMsg,
  required String belowOriginalMsg,
}) {
  final base = validatePositiveAmount(
    dealText,
    requiredMsg: requiredMsg,
    invalidMsg: invalidMsg,
  );
  if (base != null) return base;
  final deal = CurrencyFormatter.parseLocalizedDouble(dealText!);
  final orig = CurrencyFormatter.parseLocalizedDouble(originalText);
  if (orig > 0 && deal >= orig) return belowOriginalMsg;
  return null;
}
