import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';

class OrderItemsSection extends StatelessWidget {
  const OrderItemsSection({super.key, required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final count = order.orderItems.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          // ── Section header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  CustomerOrderStrings.itemCount(count),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Column headers ────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    CustomerOrderStrings.itemColumnHeader,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                Text(
                  CustomerOrderStrings.unitColumnHeader,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 32),
                Text(
                  CustomerOrderStrings.totalColumnHeader,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),

          // ── Item rows ─────────────────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            itemCount: count,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final item = order.orderItems[index];
              return _OrderItemRow(
                name: item.titleSnapshot.isNotEmpty
                    ? item.titleSnapshot
                    : item.foodOffer.title,
                qty: item.quantity,
                weightKg: item.weightKg,
                unitPrice: double.tryParse(item.unitPrice) ?? 0,
                totalPrice: double.tryParse(item.totalPrice) ?? 0,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final String name;
  final int qty;
  final double? weightKg;
  final double unitPrice;
  final double totalPrice;

  const _OrderItemRow({
    required this.name,
    required this.qty,
    this.weightKg,
    required this.unitPrice,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final qtyLabel = weightKg != null
        ? CurrencyFormatter.formatWeight(weightKg!)
        : '$qty×';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Quantity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              qtyLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Item name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Unit price
          Text(
            CurrencyFormatter.format(unitPrice),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: 16),

          // Total price
          SizedBox(
            width: 56,
            child: Text(
              CurrencyFormatter.format(totalPrice),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
