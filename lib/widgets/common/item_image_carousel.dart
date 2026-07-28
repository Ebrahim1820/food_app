import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';

/// Full-width image banner for a set of items — a single image when there's
/// only one, a swipeable slider with dot indicators when there's more than
/// one. Each entry renders via [NetworkImageWidget], which already falls
/// back to a placeholder icon for a null/empty url, so a mix of items with
/// and without real photos still gets one slide per item.
///
/// Reusable anywhere a small set of images needs the same treatment — not
/// specific to payment/checkout.
class ItemImageCarousel extends StatefulWidget {
  const ItemImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 180,
    this.borderRadius = 20,
  });

  final List<String?> imageUrls;
  final double height;
  final double borderRadius;

  @override
  State<ItemImageCarousel> createState() => _ItemImageCarouselState();
}

class _ItemImageCarouselState extends State<ItemImageCarousel> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls.isEmpty ? [null] : widget.imageUrls;
    final radius = BorderRadius.vertical(
      top: Radius.circular(widget.borderRadius),
    );

    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: NetworkImageWidget(
          imageUrl: urls.first,
          height: widget.height,
          width: double.infinity,
          borderRadius: 0,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => NetworkImageWidget(
                imageUrl: urls[i],
                height: widget.height,
                width: double.infinity,
                borderRadius: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(urls.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
