import 'package:flutter/material.dart';
import 'package:review/review.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Customer-facing "Ratings & Reviews" screen for a business — opened from
/// the "See all reviews" row on the product/business detail screen.
class BusinessReviewsScreen extends StatefulWidget {
  const BusinessReviewsScreen({
    super.key,
    required this.businessPartnerId,
    required this.businessName,
    required this.averageRating,
    required this.reviewCount,
  });

  final String businessPartnerId;
  final String businessName;
  final double averageRating;
  final int reviewCount;

  @override
  State<BusinessReviewsScreen> createState() => _BusinessReviewsScreenState();
}

class _BusinessReviewsScreenState extends State<BusinessReviewsScreen> {
  final _controller = Get.find<ReviewController>();

  @override
  void initState() {
    super.initState();
    _controller.fetchForBusiness(widget.businessPartnerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(ReviewStrings.screenTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _SummaryHeader(
            businessName: widget.businessName,
            averageRating: widget.averageRating,
            reviewCount: widget.reviewCount,
          ),
          Expanded(
            child: ReviewListBody(
              emptySubtitle: ReviewStrings.emptySubtitle,
              onRefresh: () =>
                  _controller.fetchForBusiness(widget.businessPartnerId),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.businessName,
    required this.averageRating,
    required this.reviewCount,
  });

  final String businessName;
  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Text(
            CurrencyFormatter.localizeDigits(averageRating.toStringAsFixed(1)),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < averageRating.round();
              return Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 20,
                color: filled ? AppColors.accent : AppColors.gray300,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            ReviewStrings.reviewCount(reviewCount),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
