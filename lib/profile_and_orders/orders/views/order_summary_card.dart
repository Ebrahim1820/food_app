import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/orders/controllers/order_controller.dart';
import 'package:food_app/controllers/review_controller.dart';
import 'package:food_app/profile_and_orders/orders/views/pending_order_card_footer.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model_ui.dart';
import 'package:food_app/profile_and_orders/orders/views/customer_edit_order_screen.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/profile_and_orders/profile/utils/status_helper.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';
import 'package:food_app/profile_and_orders/orders/views/order_detail_screen.dart';
import 'package:food_app/profile_and_orders/orders/views/order_status_tracker.dart';
import 'package:food_app/profile_and_orders/orders/views/rate_order_chip.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/order_detail_screen.dart'
    show isPendingOrderStatus, isTerminalOrderStatus;
import 'package:food_app/widgets/common/status_pill.dart';
import 'package:get/get.dart';

/// A single order's summary row for the "My Orders" list.
///
/// Self-contained and reusable: tapping it opens [OrderDetailScreen], and
/// the pending-order edit/cancel actions and completed-order rate action are
/// wired internally — a caller just drops in `OrderSummaryCard(order: o)`,
/// no extra plumbing required.
///
/// Layout, redesigned to match how Uber Eats/DoorDash structure a history
/// row: business name leads, price is the single largest number on the
/// card (not buried at 16px next to icon buttons), and everything else is
/// there only when it's actually useful for *this* order's state —
/// the progress bar only shows for orders still in flight (a finished
/// order re-showing "4/4 done" or a cancelled order showing a broken
/// tracker are both noise), and the address row disappears entirely for
/// pickup orders instead of announcing "No address" like an error.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order});

  final OrderModel order;

  bool get _isPending => isPendingOrderStatus(order.status);
  bool get _isTerminal => isTerminalOrderStatus(order.status);

  /// Whether this order could ever show a "rate this order" chip (only
  /// completed/delivered are eligible — whether it's already been rated is
  /// a separate, async question resolved in the footer's [Obx] below).
  bool get _canRate {
    final s = order.status.toLowerCase();
    return s == 'completed' || s == 'delivered';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusHelper.getStatusColor(order.status);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: thumbnail · name + status · price ──────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.businessPartner.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _itemsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            // Flexible + ellipsis inside StatusPill — a long
                            // localized status label (e.g. Farsi "تحویل
                            // داده شده") plus the date easily exceeds this
                            // row's ~147px budget and overflowed before
                            // either Text had any shrink/truncate behavior.
                            Flexible(
                              child: StatusPill(
                                label: order.statusLabel,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              '  ·  ${order.createdAt.split('T').first}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // This column sits outside the header's Expanded middle
                  // section, so its own content isn't automatically shrunk —
                  // an unexpectedly long price or order id (this app's order
                  // ids can be full UUIDs) could otherwise push the whole
                  // header Row wider than the card. Constrained width +
                  // ellipsis caps how much room either can claim.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(
                            double.tryParse(order.totalPrice) ?? 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          CustomerOrderStrings.orderNumber(order.id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Only orders still moving get the tracker — a finished or
              // cancelled order re-showing "how it got there" is just noise.
              if (!_isTerminal) ...[
                const SizedBox(height: 12),
                OrderStatusTracker(
                  status: order.status,
                  cancellationReason: order.cancellationReason,
                  compact: true,
                ),
              ],

              // Pickup orders have no delivery address to show — the
              // business name above already says where this is from.
              if (order.isDelivery &&
                  (order.deliveryAddress ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Footer: the one relevant action for this order's state ──
              // Pending always gets a footer (edit/cancel). Completed/
              // delivered only gets one once we *know* it isn't already
              // rated — decided from the bulk preload in
              // ReviewController.preloadReviewedOrders, not a per-card async
              // check, so this never has to reserve empty space for a
              // "maybe" state. An in-progress order (confirmed,
              // ready_for_pickup) has no action at all, so it stops after
              // the tracker.
              if (_isPending)
                PendingOrderCardFooter(
                  orderId: order.id,
                  onEdit: () =>
                      Get.to(() => CustomerEditOrderScreen(order: order)),
                  onCancel: (reason) => Get.find<OrderController>()
                      .cancelOrder(order, reason: reason),
                )
              else if (_canRate)
                Obx(() {
                  final reviewCtrl = Get.find<ReviewController>();
                  if (!reviewCtrl.reviewedOrdersLoaded.value ||
                      reviewCtrl.hasReviewedOrder(order.id)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        RateOrderChip(order: order),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  String get _itemsSummary {
    if (order.orderItems.isEmpty) return CustomerOrderStrings.itemCount(0);
    final first = order.orderItems.first.titleSnapshot.isNotEmpty
        ? order.orderItems.first.titleSnapshot
        : order.orderItems.first.foodOffer.title;
    final extra = order.orderItems.length - 1;
    return extra > 0 ? '$first +$extra' : first;
  }

  Widget _buildThumbnail() {
    final imageUrl =
        order.orderItems.isNotEmpty &&
            order.orderItems.first.foodOffer.images.isNotEmpty
        ? order.orderItems.first.foodOffer.images.first.url
        : null;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImageWidget(
        imageUrl: imageUrl,
        height: 64,
        width: 64,
        borderRadius: 14,
        fit: BoxFit.cover,
      );
    }

    final category = order.orderItems.isNotEmpty
        ? order.orderItems.first.categorySnapshot
        : '';

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(_categoryIcon(category), size: 26, color: AppColors.primary),
    );
  }

  IconData _categoryIcon(String cat) => switch (cat.toLowerCase()) {
    'fast_food' || 'fastfood' => Icons.fastfood_rounded,
    'pizza' => Icons.local_pizza_rounded,
    'bakery' || 'bread_pastries' => Icons.breakfast_dining_rounded,
    'restaurant' || 'meals' || 'meal' => Icons.dinner_dining_rounded,
    'supermarket' || 'groceries' || 'grocery' => Icons.shopping_cart_rounded,
    'cafe' || 'caffe' => Icons.local_cafe_rounded,
    'fruits_vegetables' || 'vegetables' || 'fruit' => Icons.eco_rounded,
    'hot_drinks' || 'drinks' => Icons.local_drink_rounded,
    'cheese_dairy' => Icons.egg_alt_rounded,
    'butcher' => Icons.set_meal_rounded,
    'fish' => Icons.set_meal_rounded,
    'deli_catering' => Icons.lunch_dining_rounded,
    'flowers' || 'florist' => Icons.local_florist_rounded,
    'salads' || 'salad' || 'dessert' => Icons.spa_rounded,
    _ => Icons.shopping_bag_outlined,
  };

}
