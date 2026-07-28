import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/controllers/review_controller.dart';
import 'package:food_app/strings/review_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:get/get.dart';

/// Bottom sheet for submitting a post-order star rating + optional comment
/// for a business. Opened from the order detail screen's [RateOrderButton].
class SubmitReviewSheet extends StatefulWidget {
  const SubmitReviewSheet({
    super.key,
    required this.businessPartnerId,
    required this.businessName,
    required this.orderId,
  });

  final String businessPartnerId;
  final String businessName;
  final String orderId;

  static Future<void> show(
    BuildContext context, {
    required String businessPartnerId,
    required String businessName,
    required String orderId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitReviewSheet(
        businessPartnerId: businessPartnerId,
        businessName: businessName,
        orderId: orderId,
      ),
    );
  }

  @override
  State<SubmitReviewSheet> createState() => _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends State<SubmitReviewSheet> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _showRatingError = false;

  final _controller = Get.find<ReviewController>();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _showRatingError = true);
      return;
    }
    final success = await _controller.submit(
      businessPartnerId: widget.businessPartnerId,
      rating: _rating,
      comment: _commentCtrl.text,
      orderId: widget.orderId,
    );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomSafe + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              ReviewStrings.sheetTitle,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ReviewStrings.sheetSubtitle(widget.businessName),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    onPressed: () => setState(() {
                      _rating = i + 1;
                      _showRatingError = false;
                    }),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? AppColors.accent : AppColors.gray300,
                      size: 38,
                    ),
                  );
                }),
              ),
            ),
            if (_showRatingError)
              Center(
                child: Text(
                  ReviewStrings.starsRequiredError,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _commentCtrl,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: ReviewStrings.commentHint,
                filled: true,
                fillColor: AppColors.gray50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => CustomDynamicButton(
                fullWidth: true,
                borderRadius: 14,
                isLoading: _controller.isSubmitting.value,
                label: ReviewStrings.submitButton,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
