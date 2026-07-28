import 'package:flutter/material.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:review/review.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Business owner's "Reviews" screen — read-only list of what customers have
/// said about this business, newest first.
///
/// Normally embedded as the dashboard's Reviews tab ([standalone] false, the
/// default) inside its `IndexedStack`, so it renders bare (no Scaffold/AppBar
/// — the dashboard already provides those). Set [standalone] true to push it
/// as its own screen (e.g. from the business profile screen's rating stat,
/// which isn't part of the dashboard tabs) — that wraps the same content in
/// a Scaffold with an AppBar and back button.
class BusinessReviewsScreen extends StatefulWidget {
  const BusinessReviewsScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  State<BusinessReviewsScreen> createState() => _BusinessReviewsScreenState();
}

class _BusinessReviewsScreenState extends State<BusinessReviewsScreen> {
  final _reviewCtrl = Get.find<ReviewController>();
  final _bpCtrl = Get.find<BusinessPartnerController>();
  Worker? _partnerWorker;

  @override
  void initState() {
    super.initState();
    final partnerId = _bpCtrl.partnerId;
    if (partnerId != 0) {
      _reviewCtrl.fetchForBusiness('$partnerId');
    } else {
      _partnerWorker = ever(_bpCtrl.partner, (partner) {
        if (partner != null) {
          _reviewCtrl.fetchForBusiness(partner.id);
          _partnerWorker?.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    _partnerWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Obx(() {
          final partner = _bpCtrl.partner.value;
          return _ReviewsSummaryBar(
            averageRating: partner?.rating ?? 0,
            reviewCount: partner?.reviewCount ?? 0,
          );
        }),
        Expanded(
          child: ReviewListBody(
            emptySubtitle: ReviewStrings.bizEmptySubtitle,
            onRefresh: () =>
                _reviewCtrl.fetchForBusiness('${_bpCtrl.partnerId}'),
          ),
        ),
      ],
    );

    if (!widget.standalone) return body;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(ReviewStrings.screenTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: body,
    );
  }
}

class _ReviewsSummaryBar extends StatelessWidget {
  const _ReviewsSummaryBar({
    required this.averageRating,
    required this.reviewCount,
  });

  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: AppColors.accent, size: 26),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.localizeDigits(averageRating.toStringAsFixed(1)),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· ${BusinessDashboardStrings.metricRating}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
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
