import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/controllers/review_controller.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/strings/review_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/review/submit_review_sheet.dart';
import 'package:get/get.dart';

/// Post-order rating CTA for the order detail screen. A single instance per
/// screen (unlike the order list's [RateOrderChip], which is built N-at-once
/// and needs its eligibility pre-resolved by the caller instead), so it's
/// fine for this one to check "already reviewed?" itself, asynchronously,
/// and render nothing until that resolves — no list/sliver to corrupt.
///
/// Checks whether the customer already reviewed this specific order (a
/// customer can rate every order separately, same as TGTG/Uber Eats — see
/// [ReviewController]) and swaps to a read-only "already rated" pill instead
/// of hiding entirely once reviewed.
class RateOrderButton extends StatefulWidget {
  const RateOrderButton({super.key, required this.order});

  final OrderModel order;

  bool get _eligible {
    final status = order.status.toLowerCase();
    return status == 'completed' || status == 'delivered';
  }

  @override
  State<RateOrderButton> createState() => _RateOrderButtonState();
}

class _RateOrderButtonState extends State<RateOrderButton> {
  final _controller = Get.find<ReviewController>();
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (widget._eligible) {
      _controller.checkIfReviewedOrder(widget.order.id).then((_) {
        if (mounted) setState(() => _checked = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._eligible || !_checked) return const SizedBox.shrink();

    final alreadyRated = _controller.hasReviewedOrder(widget.order.id);

    if (alreadyRated) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                ReviewStrings.alreadyRatedLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomDynamicButton(
        variant: CustomButtonVariant.outlined,
        fullWidth: true,
        borderRadius: 14,
        accentColor: AppColors.accent,
        icon: Icons.star_outline_rounded,
        label: ReviewStrings.rateOrderButton,
        onPressed: () => SubmitReviewSheet.show(
          context,
          businessPartnerId: widget.order.businessPartner.id,
          businessName: widget.order.businessPartner.businessName,
          orderId: widget.order.id,
        ),
      ),
    );
  }
}
