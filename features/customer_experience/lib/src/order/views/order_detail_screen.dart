// Customer order-detail screen for the Food market. Thin wiring layer over
// the generic OrderDetailScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/order_detail_screen.dart)
// — the same generic screen a Cosmetic order-detail screen would wire up.
// This file owns everything Food-specific: OrderController, the photo hero's
// image extraction, and every content section (status tracker, location,
// items, payment summary, actions, help) — all of which stay the existing
// widgets, unchanged.
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:customer_experience/customer_experience.dart';
import '../../discovery/views/order_detail_screen.dart'
    as shared;
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});
  final OrderModel order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final OrderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OrderController>();
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

  String _formatDate(String iso) {
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
          .where((item) => item.foodOffer.images.isNotEmpty)
          .map((item) => item.foodOffer.images.first.url)
          .whereType<String>()
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
            OrderStatusTracker(
              status: order.status,
              cancellationReason: order.cancellationReason,
            ),
            OrderLocationSection(order: order),
            OrderItemsSection(order: order),
            PaymentSummarySection(order: order),
            const SizedBox(height: 12),
            OrderActionsSection(
              orderId: order.id,
              canEdit: shared.isPendingOrderStatus(order.status),
              canCancel: shared.isPendingOrderStatus(order.status),
              onEdit: () => Get.to(() => CustomerEditOrderScreen(order: order)),
              onCancel: (reason) =>
                  controller.cancelOrder(order, reason: reason),
              extra: Column(
                children: [
                  RateOrderButton(order: order),
                  if (order.orderItems.isNotEmpty)
                    CustomDynamicButton(
                      variant: CustomButtonVariant.outlined,
                      fullWidth: true,
                      borderRadius: 14,
                      icon: Icons.replay_rounded,
                      label: CustomerOrderStrings.reorderButton,
                      onPressed: () => Get.to(
                        () => OrderCheckoutScreen(
                          offer: order.orderItems.first.foodOffer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            OrderHelpSection(order: order),
          ],
        ),
      );
    });
  }
}
