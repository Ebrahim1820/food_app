import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/constants/cosmetic/cosmetic_strings.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_order_controller.dart';
import 'package:food_app/models/product_models/product_order_model.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/common/stale_banner.dart';

/// The business partner's incoming-orders queue for Cosmetic product-orders
/// — deliberately lighter than Food's `BusinessOrdersScreen` (no live
/// Mercure subscription, no tabs/date filters for this first pass): just a
/// flat list with a single "advance" action per order, enough to prove the
/// vendor side of the order lifecycle end-to-end.
class CosmeticBusinessOrdersScreen extends StatefulWidget {
  const CosmeticBusinessOrdersScreen({
    super.key,
    required this.businessPartnerId,
  });

  final int businessPartnerId;

  @override
  State<CosmeticBusinessOrdersScreen> createState() =>
      _CosmeticBusinessOrdersScreenState();
}

class _CosmeticBusinessOrdersScreenState
    extends State<CosmeticBusinessOrdersScreen> {
  String get _partnerIri =>
      '/api/business-partners/${widget.businessPartnerId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          Get.find<ProductOrderController>().fetchBusinessOrders(_partnerIri),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductOrderController>();
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.navy,
        title: Text(CosmeticStrings.businessOrdersTitle),
      ),
      body: Obx(() {
        final isLoading =
            ctrl.isLoadingBusinessOrders.value && ctrl.businessOrders.isEmpty;
        final hasError =
            ctrl.businessOrdersError.value.isNotEmpty &&
            ctrl.businessOrders.isEmpty;

        if (isLoading) return const Center(child: CircularProgressIndicator());
        if (hasError) {
          return ErrorRetryWidget(
            message: ctrl.businessOrdersError.value,
            onRetry: () => ctrl.fetchBusinessOrders(_partnerIri),
          );
        }
        if (ctrl.businessOrders.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: CosmeticStrings.businessOrdersEmptyTitle,
            subtitle: CosmeticStrings.businessOrdersEmptySubtitle,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.fetchBusinessOrders(_partnerIri),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ctrl.businessOrders.length,
            itemBuilder: (context, i) => _BusinessOrderCard(
              order: ctrl.businessOrders[i],
              onAdvance: (status) =>
                  _advance(ctrl.businessOrders[i].id, status),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _advance(String orderId, String newStatus) async {
    final ok = await Get.find<ProductOrderController>().advanceBusinessOrder(
      orderId,
      newStatus,
      _partnerIri,
    );
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(CosmeticStrings.businessOrderStatusUpdated, '');
    } else {
      AppSnackbar.error(CosmeticStrings.businessOrderUpdateError, '');
    }
  }
}

class _BusinessOrderCard extends StatelessWidget {
  const _BusinessOrderCard({required this.order, required this.onAdvance});

  final ProductOrderModel order;
  final void Function(String newStatus) onAdvance;

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusEnums.fromValue(order.status);
    final next = status.next;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  CosmeticStrings.orderNumber(order.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.successDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '€${order.totalPrice}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.successDark,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onAdvance(next.value),
                    child: Text(
                      _advanceLabel(next),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (status.isActiveForCancel) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.error,
                    ),
                    onPressed: () => onAdvance('cancelled'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _advanceLabel(OrderStatusEnums next) => switch (next) {
    OrderStatusEnums.confirmed => CosmeticStrings.businessOrderConfirmButton,
    OrderStatusEnums.readyForPickup => CosmeticStrings.businessOrderReadyButton,
    OrderStatusEnums.completed => CosmeticStrings.businessOrderCompleteButton,
    _ => next.label,
  };
}

extension on OrderStatusEnums {
  bool get isActiveForCancel =>
      this == OrderStatusEnums.pending ||
      this == OrderStatusEnums.confirmed ||
      this == OrderStatusEnums.readyForPickup;
}
