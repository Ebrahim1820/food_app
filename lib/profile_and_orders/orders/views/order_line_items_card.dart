import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';

/// One line item in an order review list — market-agnostic (title/image/
/// quantity text/price only, no FoodOfferModel or ProductModel), so it's
/// reusable anywhere an itemized order needs reviewing: the generic
/// PaymentScreen today, any future cart or order-recap screen tomorrow.
class OrderLineItem {
  const OrderLineItem({
    required this.title,
    this.imageUrl,
    required this.quantityLabel,
    required this.totalPrice,
  });

  final String title;
  final String? imageUrl;

  /// Prebuilt by the caller since only it knows whether this is "×3" or
  /// "1.5 kg".
  final String quantityLabel;
  final double totalPrice;
}

/// Card listing every [OrderLineItem] with a thumbnail, name, quantity and
/// line price, headed by an item-count label — the "how many items and
/// what they are" review a payment step needs beyond just a subtotal.
class OrderLineItemsCard extends StatelessWidget {
  const OrderLineItemsCard({super.key, required this.items});

  final List<OrderLineItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  CustomerOrderStrings.itemCount(items.length),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) => _ItemRow(item: items[index]),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          NetworkImageWidget(
            imageUrl: item.imageUrl,
            height: 44,
            width: 44,
            borderRadius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.quantityLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            CurrencyFormatter.format(item.totalPrice),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
