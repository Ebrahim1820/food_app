import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';

/// Shared +/- quantity stepper for the business "create/edit listing" forms
/// — was reimplemented separately per screen (Food create, Food edit,
/// Cosmetic create, cart, cosmetic checkout) with minor styling drift.
///
/// The number in the middle is also directly editable — tap it and type a
/// value instead of tapping +/- repeatedly. Every keystroke reports the
/// clamped value via [onChanged]; the +/- buttons write the field's
/// displayed text themselves rather than waiting for a rebuild, matching
/// the pattern already used by the weight-quantity field in checkout
/// (`order_checkout_screen.dart`'s `_WeightInputWidget`) — relying on
/// focus-loss/`didUpdateWidget` to resync the display is unreliable here
/// because tapping the +/- `IconButton`s doesn't reliably blur this field.
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.accentColor = AppColors.primary,
  });

  final int quantity;
  final VoidCallback onIncrease;

  /// Pass `null` (rather than checking inside this widget) when the
  /// quantity is already at its minimum — matches how every existing call
  /// site already disables the button.
  final VoidCallback? onDecrease;

  /// Called on every keystroke with the clamped value — the caller owns
  /// the actual state (this widget never assumes it can read it back
  /// synchronously).
  final ValueChanged<int> onChanged;

  final int min;
  final int? max;
  final Color accentColor;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _digits(widget.quantity));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _digits(int v) => CurrencyFormatter.localizeDigits('$v');

  int _clamp(int v) {
    var out = v < widget.min ? widget.min : v;
    final max = widget.max;
    if (max != null && out > max) out = max;
    return out;
  }

  void _setText(int v) {
    _ctrl.value = TextEditingValue(
      text: _digits(v),
      selection: TextSelection.collapsed(offset: _digits(v).length),
    );
  }

  void _handleIncrease() {
    widget.onIncrease();
    _setText(_clamp(widget.quantity + 1));
  }

  void _handleDecrease() {
    widget.onDecrease?.call();
    _setText(_clamp(widget.quantity - 1));
  }

  void _handleTyped(String text) {
    if (text.isEmpty) return;
    final parsed = CurrencyFormatter.parseLocalizedDouble(text).round();
    widget.onChanged(_clamp(parsed));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.navy,
            onPressed: widget.onDecrease == null ? null : _handleDecrease,
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹]')),
              ],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
              onChanged: _handleTyped,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: widget.accentColor,
            onPressed: _handleIncrease,
          ),
        ],
      ),
    );
  }
}
