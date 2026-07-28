import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_checkout_strings.dart';
import 'package:food_app/profile_and_orders/orders/constants/order_string.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';

/// Market-agnostic quantity +/-/type stepper, shared by every screen that
/// lets a customer pick a piece-based quantity against a stock ceiling
/// (checkout, and the customer Edit Order screen for both Food and
/// Cosmetic). Generalized from what used to be checkout-only
/// `BuildQuantitySelectorWidget` so all three call sites get the same
/// correct behavior instead of each reimplementing (and potentially
/// under-implementing) the stock cap.
///
/// Callers own what [maxQuantity] means for their context — checkout passes
/// the offer's live `quantityAvailable`, while Edit Order must pass
/// `quantityAvailable + currentlyOrderedQuantity` since that stock is
/// already reserved by the order being edited. [displayAvailable] is shown
/// in the "N available" label and defaults to [maxQuantity] — Edit Order
/// overrides it to the raw, un-added stock count so the label reads as the
/// customer would expect ("5 available", not "7").
class QuantityStepperField extends StatefulWidget {
  const QuantityStepperField({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    this.showAvailableLabel = true,
    this.displayAvailable,
  });

  final RxInt quantity;
  final int maxQuantity;

  /// Whether to show the "N available" label next to the title.
  final bool showAvailableLabel;

  /// Overrides what [maxQuantity]'s value the "N available" label shows —
  /// see class doc.
  final int? displayAvailable;

  @override
  State<QuantityStepperField> createState() => _QuantityStepperFieldState();
}

class _QuantityStepperFieldState extends State<QuantityStepperField> {
  late final TextEditingController _ctrl;
  final _focusNode = FocusNode();

  RxInt get quantity => widget.quantity;
  int get _maxQty => widget.maxQuantity < 1 ? 1 : widget.maxQuantity;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: CurrencyFormatter.localizeDigits('${quantity.value}'),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setText(int v) {
    final text = CurrencyFormatter.localizeDigits('$v');
    _ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // Tapping +/- doesn't reliably blur this field, so it writes the
  // displayed text itself rather than relying on a rebuild to resync it.
  void _decrement() {
    if (quantity.value <= 1) return;
    quantity.value--;
    _setText(quantity.value);
  }

  void _increment() {
    if (quantity.value >= _maxQty) return;
    quantity.value++;
    _setText(quantity.value);
  }

  // Deliberately does NOT clamp to [1, _maxQty] here — silently correcting
  // an over-limit typed value (e.g. typing "4" with only 1 available) made
  // the real quantity stay valid underneath, so a confirm/save button
  // checking `quantity.value` against the max never actually disabled even
  // though the box visibly showed an over-limit number. Only the
  // empty/non-numeric case is guarded; an out-of-range value is left as
  // typed so the invalid state is real and the caller's button correctly
  // disables until it's corrected.
  void _handleTyped(String text) {
    if (text.isEmpty) {
      quantity.value = 0;
      return;
    }
    quantity.value = CurrencyFormatter.parseLocalizedDouble(text).round();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isInvalid = quantity.value < 1 || quantity.value > _maxQty;
      // Catches changes that didn't come from this widget's own
      // +/-/typing handlers — e.g. a caller clamping the quantity down
      // after a fresher stock count comes back. Skipped while focused so
      // it never fights an in-progress keystroke.
      if (!_focusNode.hasFocus) {
        final digits = CurrencyFormatter.localizeDigits('${quantity.value}');
        if (_ctrl.text != digits) _ctrl.text = digits;
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isInvalid ? AppColors.error : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  OrderString.quantity,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (widget.showAvailableLabel)
                  Text(
                    CustomerCheckoutStrings.availableQuantity(
                      widget.displayAvailable ?? widget.maxQuantity,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            Center(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isInvalid ? AppColors.errorLight : AppColors.gray100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionButton(
                      icon: Icons.remove,
                      enabled: quantity.value > 1,
                      onTap: _decrement,
                    ),

                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9۰-۹]'),
                          ),
                        ],
                        onChanged: _handleTyped,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isInvalid
                              ? AppColors.errorDark
                              : AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    _actionButton(
                      icon: Icons.add,
                      enabled: quantity.value < _maxQty,
                      onTap: _increment,
                    ),
                  ],
                ),
              ),
            ),

            if (isInvalid) ...[
              const SizedBox(height: 8),
              Text(
                CustomerCheckoutStrings.quantityExceedsAvailable(_maxQty),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.errorDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _actionButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.gray300,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}
