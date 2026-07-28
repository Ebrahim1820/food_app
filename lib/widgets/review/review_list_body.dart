import 'package:flutter/material.dart';
import 'package:food_app/controllers/review_controller.dart';
import 'package:food_app/strings/review_strings.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/review/review_card.dart';
import 'package:get/get.dart';

/// Paginated review list — loading/empty states, infinite scroll, and the
/// [ReviewCard] rows. Shared by the customer-facing "Ratings & Reviews"
/// screen and the business owner's Reviews dashboard tab; the two differ
/// only in their header and how they kick off the initial fetch, so both
/// wrap this in their own `Expanded` once [ReviewController.reviews] is
/// populated for whichever business is being viewed.
class ReviewListBody extends StatefulWidget {
  const ReviewListBody({
    super.key,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  final String emptySubtitle;

  /// Pull-to-refresh handler — each caller re-fetches for whichever business
  /// it's showing. Live Mercure updates cover the business owner's own
  /// Reviews tab already; this is the manual fallback (and the only way to
  /// refresh on the customer-facing screen, which has no live subscription).
  final Future<void> Function() onRefresh;

  @override
  State<ReviewListBody> createState() => _ReviewListBodyState();
}

class _ReviewListBodyState extends State<ReviewListBody> {
  final _controller = Get.find<ReviewController>();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      _controller.fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.reviews.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_controller.reviews.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.rate_review_outlined,
          title: ReviewStrings.emptyTitle,
          subtitle: widget.emptySubtitle,
        );
      }
      final reviews = _controller.reviews;
      final isLoadingMore = _controller.isLoadingMore.value;
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == reviews.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              );
            }
            return ReviewCard(review: reviews[index]);
          },
        ),
      );
    });
  }
}
