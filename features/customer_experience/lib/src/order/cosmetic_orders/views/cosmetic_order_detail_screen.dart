// Customer order-detail screen for Cosmetics (and any other non-Food
// market). Thin wiring layer over the generic OrderDetailScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/order_detail_screen.dart)
// — the same generic screen Food's OrderDetailScreen wires up.
//
// Deliberately simpler than Food's items/payment/help cards — no reorder,
// no pickup-window tracker — since ProductOrderModel doesn't carry that data
// yet. Edit/Cancel now share the same OrderActionsSection Food uses,
// refreshed via ProductOrderController.fetchOrderById the same way Food's
// screen refreshes via OrderController.fetchOrderById (both need the detail
// endpoint, not the list endpoint, for a non-null nested product/foodOffer).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:customer_experience/customer_experience.dart';
import 'package:payment/payment.dart';
import 'package:profile/profile.dart';
import '../../../discovery/views/order_detail_screen.dart'
    as shared;
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'package:i18n/i18n.dart';

class CosmeticOrderDetailScreen extends StatefulWidget {
  const CosmeticOrderDetailScreen({super.key, required this.order});

  final ProductOrderModel order;

  @override
  State<CosmeticOrderDetailScreen> createState() =>
      _CosmeticOrderDetailScreenState();
}

class _CosmeticOrderDetailScreenState extends State<CosmeticOrderDetailScreen> {
  late final ProductOrderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProductOrderController>();
    controller.selectedOrder.value = widget.order;
    controller.fetchOrderById(widget.order.id);
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return CurrencyFormatter.localizeDigits(
        '${_months[dt.month - 1]} ${dt.day}, ${dt.year} · '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final order = controller.selectedOrder.value ?? widget.order;

      final imageUrls = order.orderItems
          .where((item) => item.product.images.isNotEmpty)
          .map((item) => item.product.images.first.url)
          .where((url) => url.isNotEmpty)
          .toList();

      return shared.OrderDetailScreen(
        config: shared.OrderDetailConfig(
          orderNumberLabel: CustomerOrderStrings.orderNumber(order.id),
          status: order.status,
          formattedDate: _formatDate(order.createdAt),
          logisticsLabel: CustomerOrderStrings.deliveryLabel,
          imageUrls: imageUrls,
          isRefreshing: controller.isDetailLoading,
          sections: [
            _StatusCard(order: order),
            _ItemsCard(order: order),
            _PaymentSummary(order: order),
            const SizedBox(height: 12),
            OrderActionsSection(
              orderId: order.id,
              canEdit: shared.isPendingOrderStatus(order.status),
              canCancel: shared.isPendingOrderStatus(order.status),
              onEdit: () => Get.to(() => CosmeticEditOrderScreen(order: order)),
              onCancel: (reason) async {
                await controller.cancelOrder(order.id, reason: reason);
              },
            ),
            const SizedBox(height: 6),
            _HelpCard(order: order),
          ],
        ),
      );
    });
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});
  final ProductOrderModel order;

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final color = StatusHelper.getStatusColor(order.status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.errorLight : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: isCancelled
            ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
            : null,
        boxShadow: isCancelled
            ? null
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled ? Icons.cancel_rounded : Icons.receipt_long_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shared.orderStatusLabel(order.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (isCancelled &&
                    (order.cancellationReason?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${CustomerOrderStrings.cancellationReasonLabel}: '
                    '${order.cancellationReason!.trim()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.errorDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Items card ──────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final ProductOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CustomerOrderStrings.itemColumnHeader,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final item in order.orderItems) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.titleSnapshot.isNotEmpty
                        ? item.titleSnapshot
                        : item.product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(
                    double.tryParse(item.totalPrice) ?? 0,
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (item != order.orderItems.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Payment summary ───────────────────────────────────────────────────────────

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.order});
  final ProductOrderModel order;

  Color _paymentStatusColor(String status) => switch (status.toLowerCase()) {
    'paid' => AppColors.successDark,
    'refunded' => AppColors.warningDark,
    _ => AppColors.infoDark,
  };

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
          _Row(
            title: CustomerOrderStrings.paymentSubtotal,
            value: CurrencyFormatter.format(
              double.tryParse(order.subtotal) ?? 0,
            ),
          ),
          const SizedBox(height: 8),
          _Row(
            title: CustomerOrderStrings.paymentDelivery,
            value: CurrencyFormatter.format(
              double.tryParse(order.deliveryFee) ?? 0,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 20),
          _Row(
            title: CustomerOrderStrings.paymentTotal,
            value: CurrencyFormatter.format(
              double.tryParse(order.totalPrice) ?? 0,
            ),
            bold: true,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _Row(
            title: CustomerOrderStrings.paymentMethodLabel,
            value: order.paymentMethod == 'cash'
                ? 'payment_methodCash'.tr
                : 'payment_methodCard'.tr,
          ),
          const SizedBox(height: 6),
          _Row(
            title: CustomerOrderStrings.paymentStatusLabel,
            value: CustomerPaymentStrings.paymentStatusLabel(
              order.paymentStatus,
            ),
            valueColor: _paymentStatusColor(order.paymentStatus),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.value,
    this.bold = false,
    this.valueColor,
  });
  final String title;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AppColors.black : AppColors.gray700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? (bold ? AppColors.black : AppColors.gray800),
          ),
        ),
      ],
    );
  }
}

// ── Help card ─────────────────────────────────────────────────────────────────

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.order});
  final ProductOrderModel order;

  Future<void> _contactBusiness(String? phone, String? email) async {
    final uri = (phone?.trim().isNotEmpty ?? false)
        ? Uri.parse('tel:${phone!.trim()}')
        : Uri.parse('mailto:${email!.trim()}');
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e, st) {
      AppLogger.error(
        'CosmeticOrderDetailScreen',
        'Could not launch $uri',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = order.businessPartner.contactPhone;
    final email = order.businessPartner.contactEmail;
    final hasBusinessContact =
        (phone?.trim().isNotEmpty ?? false) ||
        (email?.trim().isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                CustomerOrderStrings.helpTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CustomerOrderStrings.helpSubtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (hasBusinessContact) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactBusiness(phone, email),
                    icon: const Icon(Icons.storefront_outlined, size: 16),
                    label: Text(
                      CustomerOrderStrings.contactBusinessButton,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Get.to(() => const CustomerHelpScreen()),
                  icon: const Icon(Icons.headset_mic_outlined, size: 16),
                  label: Text(
                    CustomerOrderStrings.contactSupport,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
