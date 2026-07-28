// Customer order-history screen for Cosmetics (and any other non-Food
// market). Thin wiring layer over the generic OrderListScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/order_list_screen.dart)
// — the same generic screen Food's OrderListScreen wires up. This file owns
// everything Cosmetic-specific: ProductOrderController and the order row
// widget. No swipe-to-delete yet (matches the previous version of this
// screen — Product orders have no delete flow defined yet, only cancel).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:models/models.dart';
import 'package:food_app/constants/cosmetic/cosmetic_strings.dart';
import 'package:food_app/screens/cosmetic_teil/orders/views/cosmetic_edit_order_screen.dart';
import 'package:food_app/screens/cosmetic_teil/orders/views/cosmetic_order_detail_screen.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_order_controller.dart';
import 'package:food_app/models/product_models/product_order_model.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/profile_and_orders/orders/views/order_status_tracker.dart';
import 'package:food_app/profile_and_orders/orders/views/pending_order_card_footer.dart';
import 'package:food_app/profile_and_orders/profile/utils/status_helper.dart';
import 'package:food_app/screens/cosmetic_teil/customer_views/customer_cosmetic_product_detail_screen.dart'
    show cosmeticCategoryIcon;
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/order_detail_screen.dart'
    show isPendingOrderStatus, isTerminalOrderStatus, orderStatusLabel;
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/order_list_screen.dart'
    as shared;
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/status_pill.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';

/// Customer's product-order history for Cosmetics — a real screen replacing
/// the "coming soon" placeholder `AppShellScreen` previously showed for the
/// Orders tab while `activeMarket == 'cosmetic'`.
class CosmeticOrderListScreen extends StatefulWidget {
  const CosmeticOrderListScreen({super.key});

  @override
  State<CosmeticOrderListScreen> createState() =>
      _CosmeticOrderListScreenState();
}

class _CosmeticOrderListScreenState extends State<CosmeticOrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.find<ProductOrderController>().fetchOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductOrderController>();

    return shared.OrderListScreen<ProductOrderModel>(
      config: shared.OrderListConfig<ProductOrderModel>(
        rawOrders: controller.orders,
        filterAndSort: (_) => controller.filteredOrders,
        keyOf: (order) => order.id,

        isLoading: controller.isLoading,
        isLoadingMore: controller.isLoadingMore,
        errorMessage: controller.errorMessage,
        isFromCache: controller.isFromCache,

        searchQuery: controller.searchQuery,
        sortOrder: controller.sortOrder,
        statusFilter: controller.statusFilter,
        dateFilter: controller.dateFilter,

        onRefresh: controller.fetchOrders,
        onLoadMore: () => controller.fetchOrders(loadMore: true),

        itemBuilder: (order) => CosmeticOrderCard(order: order),
        // No swipe-to-delete for Product orders yet.
        deleteConfig: null,

        // Active/Done sections — mirrors Food's split (no separate
        // "incoming" bucket for the customer view).
        isDone: (order) => isTerminalOrderStatus(order.status),
        activeSectionLabel: ProductStrings.ordersSectionActive,
        doneSectionLabel: ProductStrings.ordersSectionDone,

        sortNewestLabel: ProductStrings.ordersSortNewest,
        sortOldestLabel: ProductStrings.ordersSortOldest,
        sortPriceLabel: (sort) => switch (sort) {
          CustomerOrderSort.priceLowHigh =>
            ProductStrings.ordersSortPriceLowHigh,
          CustomerOrderSort.priceHighLow =>
            ProductStrings.ordersSortPriceHighLow,
          _ => ProductStrings.ordersSortPrice,
        },
        filterTodayLabel: ProductStrings.ordersFilterToday,
        filterThisWeekLabel: ProductStrings.ordersFilterThisWeek,

        emptyTitle: CosmeticStrings.ordersEmptyTitle,
        emptySubtitle: CosmeticStrings.ordersEmptySubtitle,
        filteredEmptyTitle: ProductStrings.ordersFilteredEmptyTitle,
        filteredEmptySubtitle: ProductStrings.ordersFilteredEmptySubtitle,
        clearFiltersButtonLabel: ProductStrings.ordersClearFiltersButton,
        tryAgainLabel: ProductStrings.ordersTryAgain,
        onClearFilters: () {
          controller.searchQuery.value = '';
          controller.statusFilter.value = CustomerOrderStatusFilter.all;
          controller.dateFilter.value = OrderDateFilter.all;
          controller.sortOrder.value = CustomerOrderSort.newest;
        },
      ),
    );
  }
}

/// Mirrors Food's `OrderSummaryCard` layout — same thumbnail-left/price-right
/// header, left status-color border, compact status tracker, shadow, corner
/// radius — so the two markets' order lists read as one product rather than
/// two differently-designed screens. What's missing on purpose: the
/// edit/cancel/rate footer, since Product orders have no edit/cancel-by-swipe
/// or rating flow yet (see the module doc comment above).
class CosmeticOrderCard extends StatelessWidget {
  const CosmeticOrderCard({super.key, required this.order});

  final ProductOrderModel order;

  bool get _isTerminal => isTerminalOrderStatus(order.status);

  bool get _isDelivery =>
      (order.deliveryAddress?.isNotEmpty ?? false) &&
      (double.tryParse(order.deliveryFee) ?? 0) > 0;

  String get _itemsSummary {
    if (order.orderItems.isEmpty) return CustomerOrderStrings.itemCount(0);
    final first = order.orderItems.first;
    final title = first.titleSnapshot.isNotEmpty
        ? first.titleSnapshot
        : first.product.title;
    final extra = order.orderItems.length - 1;
    return extra > 0 ? '$title +$extra' : title;
  }

  Widget _buildThumbnail() {
    final imageUrl =
        order.orderItems.isNotEmpty &&
            order.orderItems.first.product.images.isNotEmpty
        ? order.orderItems.first.product.images.first.url
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
      child: Icon(
        cosmeticCategoryIcon(category),
        size: 26,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusHelper.getStatusColor(order.status);

    return GestureDetector(
      onTap: () => Get.to(() => CosmeticOrderDetailScreen(order: order)),
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
              // ── Header: thumbnail · name + status · price ────────────────
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
                            Flexible(
                              child: StatusPill(
                                label: orderStatusLabel(order.status),
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

              if (!_isTerminal) ...[
                const SizedBox(height: 12),
                OrderStatusTracker(
                  status: order.status,
                  cancellationReason: order.cancellationReason,
                  compact: true,
                ),
              ],

              if (_isDelivery) ...[
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

              if (isPendingOrderStatus(order.status))
                PendingOrderCardFooter(
                  orderId: order.id,
                  onEdit: () =>
                      Get.to(() => CosmeticEditOrderScreen(order: order)),
                  onCancel: (reason) async {
                    await Get.find<ProductOrderController>().cancelOrder(
                      order.id,
                      reason: reason,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
