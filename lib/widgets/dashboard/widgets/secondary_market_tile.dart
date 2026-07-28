import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_app/widgets/dashboard_icons.dart';
import 'package:food_app/models/dashboard_model.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';

/// The market shown beside the hero tile — same height, narrower, solid
/// accent colour (or a rotating carousel of its images, if it has any) with
/// the icon, title and tagline stacked at the bottom, matching the hero
/// tile's style at a smaller scale.
class SecondaryMarketTile extends StatefulWidget {
  const SecondaryMarketTile({
    super.key,
    required this.market,
    required this.onTap,
    this.height = 190,
  });

  final DashboardMarket market;
  final VoidCallback onTap;
  final double height;

  @override
  State<SecondaryMarketTile> createState() => _SecondaryMarketTileState();
}

class _SecondaryMarketTileState extends State<SecondaryMarketTile> {
  final _pageController = PageController();
  Timer? _timer;
  int _page = 0;

  List<String> get _images {
    final local = marketLocalBannerImages(widget.market.key);
    return local.isNotEmpty ? local : widget.market.heroImages;
  }

  @override
  void initState() {
    super.initState();
    if (_images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        _page = (_page + 1) % _images.length;
        _pageController.animateToPage(
          _page,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final market = widget.market;
    final height = widget.height;
    final tagline = marketTagline(market.key);
    final images = _images;
    final promoBadge = marketPromoBadge(market.key);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: marketAccentColor(market.key),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Icon(
                    marketIcon(market.key),
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                itemBuilder: (context, i) => images[i].startsWith('assets/')
                    ? Image.asset(
                        images[i],
                        height: height,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : NetworkImageWidget(
                        imageUrl: images[i],
                        height: height,
                        borderRadius: 0,
                      ),
              ),

            if (images.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: _Dots(count: images.length, activeIndex: _page),
              ),

            if (promoBadge != null)
              Positioned(
                top: 12,
                left: 12,
                child: _PromoBadge(label: promoBadge),
              ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB3000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    marketLabel(market.key, market.label).toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (tagline.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(left: 4),
          width: active ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 1 : 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Smaller-scale sibling of [HeroMarketTile]'s promo badge, matching this
/// tile's narrower proportions.
class _PromoBadge extends StatelessWidget {
  const _PromoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
