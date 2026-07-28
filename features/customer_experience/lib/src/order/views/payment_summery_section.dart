import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:payment/payment.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';

class PaymentSummarySection extends StatelessWidget {
  const PaymentSummarySection({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            title: CustomerOrderStrings.paymentSubtotal,
            value: CurrencyFormatter.format(
              double.tryParse(order.subtotal) ?? 0,
            ),
          ),
          const SizedBox(height: 8),

          _SummaryRow(
            title: CustomerOrderStrings.paymentDelivery,
            value: CurrencyFormatter.format(
              double.tryParse(order.deliveryFee) ?? 0,
            ),
          ),
          const SizedBox(height: 12),

          const Divider(height: 20),

          _SummaryRow(
            title: CustomerOrderStrings.paymentTotal,
            value: CurrencyFormatter.format(
              double.tryParse(order.totalPrice) ?? 0,
            ),
            bold: true,
            isTotal: true,
          ),

          if (order.paymentStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _SummaryRow(
              title: CustomerOrderStrings.paymentMethodLabel,
              value: order.paymentMethod == 'cash'
                  ? 'payment_methodCash'.tr
                  : 'payment_methodCard'.tr,
            ),
            const SizedBox(height: 6),
            _SummaryRow(
              title: CustomerOrderStrings.paymentStatusLabel,
              value: CustomerPaymentStrings.paymentStatusLabel(
                order.paymentStatus,
              ),
              valueColor: _paymentStatusColor(order.paymentStatus),
            ),
          ],
        ],
      ),
    );
  }

  Color _paymentStatusColor(String status) => switch (status.toLowerCase()) {
    'paid' => AppColors.successDark,
    'refunded' => AppColors.warningDark,
    _ => AppColors.infoDark, // pending and any unknown state → blue
  };
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final bool bold;
  final bool isTotal;
  final Color? valueColor;

  const _SummaryRow({
    required this.title,
    required this.value,
    this.bold = false,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: isTotal ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: isTotal ? AppColors.black : AppColors.gray700,
    );

    final valueStyle = TextStyle(
      fontSize: isTotal ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: valueColor ?? (isTotal ? AppColors.black : AppColors.gray800),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
