import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';

/// Renders a single field's label — injected by the caller so each market
/// can keep its own label style (e.g. Food's create screens use a bold
/// section-style [FormFieldLabel] above each field, while Food's edit
/// screen groups several price rows under one bold section header and
/// labels each field with the lighter [FormFieldCaption] instead).
typedef PriceFieldLabelBuilder = Widget Function(String label);

/// Digits allowed in a price/weight field — Latin and Persian numerals plus
/// separators. Shared so every price field in every market's form accepts
/// the same input.
final moneyInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9.,۰-۹]'),
);

/// Farsi-aware currency prefix/suffix for a price field, matching the
/// `€ ` / ` تومان` branching every price field in the app already does via
/// [CurrencyFormatter.isFarsi].
({String? prefix, String? suffix}) currencyAffixes() => (
  prefix: CurrencyFormatter.isFarsi ? null : '€ ',
  suffix: CurrencyFormatter.isFarsi ? ' ${CurrencyFormatter.faToman}' : null,
);

/// Farsi-aware "kg" suffix for a weight field, matching the `kg` / `کیلو`
/// branching every weight field in the app already does.
({String? prefix, String? suffix}) weightAffixes() => (
  prefix: null,
  suffix: ' ${CurrencyFormatter.isFarsi ? CurrencyFormatter.faKgUnit : 'kg'}',
);

/// "Sell by weight" toggle shown above the price fields — switching it
/// swaps which field set (piece-based vs. weight-based) is rendered below.
class WeightModeToggle extends StatelessWidget {
  const WeightModeToggle({
    super.key,
    required this.isWeightBased,
    required this.onChanged,
    required this.titleLabel,
    required this.weightHint,
    required this.pieceHint,
  });

  final bool isWeightBased;
  final ValueChanged<bool> onChanged;
  final String titleLabel;
  final String weightHint;
  final String pieceHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          const Icon(Icons.scale_outlined, color: AppColors.navy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isWeightBased ? weightHint : pieceHint,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),
          Switch(
            value: isWeightBased,
            activeThumbColor: AppColors.successDark,
            activeTrackColor: AppColors.successLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// A side-by-side pair of price/weight `TextFormField`s — the structural
/// pattern (Row + two Expanded fields + shared decoration/formatter wiring)
/// that was repeated 4 times per screen (orig/deal, perKg/origPerKg,
/// weight-available/min-order) across every market's create/edit form.
class PriceFieldPair extends StatelessWidget {
  const PriceFieldPair({
    super.key,
    required this.leftLabel,
    required this.leftController,
    required this.leftHint,
    required this.labelBuilder,
    this.leftValidator,
    this.leftOnChanged,
    this.rightLabel,
    this.rightController,
    this.rightHint,
    this.rightValidator,
    this.rightOnChanged,
    this.prefix,
    this.suffix,
  });

  final String leftLabel;
  final TextEditingController leftController;
  final String leftHint;
  final FormFieldValidator<String>? leftValidator;
  final ValueChanged<String>? leftOnChanged;

  /// The right-hand field is optional — [minOrderKg] and similar
  /// once-optional fields are still rendered as a pair for layout
  /// consistency, but some callers only need one field on this row.
  final String? rightLabel;
  final TextEditingController? rightController;
  final String? rightHint;
  final FormFieldValidator<String>? rightValidator;
  final ValueChanged<String>? rightOnChanged;

  final PriceFieldLabelBuilder labelBuilder;
  final String? prefix;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final right = rightController;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _field(
            leftLabel,
            leftController,
            leftHint,
            leftValidator,
            leftOnChanged,
          ),
        ),
        if (right != null) ...[
          const SizedBox(width: 14),
          Expanded(
            child: _field(
              rightLabel!,
              right,
              rightHint!,
              rightValidator,
              rightOnChanged,
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelBuilder(label),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [moneyInputFormatter],
          decoration: _decoration(hint),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
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
