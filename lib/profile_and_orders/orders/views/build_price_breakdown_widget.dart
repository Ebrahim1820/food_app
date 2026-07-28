import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_checkout_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';

/// A widget that displays the order price summary box.
///
/// Shows subtotal, an optional delivery fee (omitted if 0),
/// and a highlighted final total.
class BuildPriceBreakDownrWidget extends StatelessWidget {
  const BuildPriceBreakDownrWidget({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    // deliveryFee is 0 for pickup orders — the row is omitted entirely
    // rather than shown as "€0.00" since it doesn't apply at all.
    final showDeliveryFee = deliveryFee > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          _priceRow(
            CustomerCheckoutStrings.subtotalLabel,
            CurrencyFormatter.format(subtotal),
          ),
          if (showDeliveryFee) ...[
            const SizedBox(height: 8),
            _priceRow(
              CustomerCheckoutStrings.deliveryFeeLabel,
              CurrencyFormatter.format(deliveryFee),
            ),
          ],
          const Divider(height: 20),
          _priceRow(
            CustomerCheckoutStrings.totalLabel,
            CurrencyFormatter.format(total),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    final style = TextStyle(
      fontSize: isBold ? 16 : 14,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: style),
      ],
    );
  }
}
