import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:review/review.dart';

/// Compact "★ Rate your order" chip for a completed order's list-card
/// footer. Purely presentational — always renders the chip; the caller
/// ([OrderSummaryCard]) is responsible for only building this once it has
/// confirmed (via [ReviewController.reviewedOrdersLoaded] +
/// `hasReviewedOrder`) that the order is eligible and not yet rated.
///
/// Deliberately has no internal "is it eligible / already rated?" check of
/// its own (unlike the full-width [RateOrderButton] on the order detail
/// screen) — doing that per-card, asynchronously, after the list had
/// already laid out was what caused a real ListView/sliver layout crash
/// with ~30 cards on screen at once. Pushing that decision up to the
/// caller, backed by one bulk preload instead of N per-card checks, is the
/// fix — see [[project_reviews_feature]].
class RateOrderChip extends StatelessWidget {
  const RateOrderChip({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SubmitReviewSheet.show(
        context,
        businessPartnerId: order.businessPartner.id,
        businessName: order.businessPartner.businessName,
        orderId: order.id,
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_outline_rounded,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 4),
            Text(
              ReviewStrings.rateOrderButton,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
