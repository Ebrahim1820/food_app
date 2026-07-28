import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_app/models/dashboard_model.dart';
import 'package:food_app/widgets/dashboard_icons.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';

/// Large card for the top-priority live market (Food today), with a
/// rotating carousel of [DashboardMarket.heroImages]. Falls back to a solid
/// accent-colour tile when there are no images yet (e.g. Cosmetics has none
/// wired up server-side).
class HeroMarketTile extends StatefulWidget {
  const HeroMarketTile({
    super.key,
    required this.market,
    required this.onTap,
    this.height = 190,
  });

  final DashboardMarket market;
  final VoidCallback onTap;
  final double height;

  @override
  State<HeroMarketTile> createState() => _HeroMarketTileState();
}

class _HeroMarketTileState extends State<HeroMarketTile> {
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
    final images = _images;
    final tagline = marketTagline(widget.market.key);
    final promoBadge = marketPromoBadge(widget.market.key);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: marketAccentColor(widget.market.key),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              Center(
                child: Icon(
                  marketIcon(widget.market.key),
                  size: 52,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                itemBuilder: (context, i) => images[i].startsWith('assets/')
                    ? Image.asset(
                        images[i],
                        height: widget.height,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : NetworkImageWidget(
                        imageUrl: images[i],
                        height: widget.height,
                        borderRadius: 0,
                      ),
              ),

            // Gradient scrim so the label stays readable over any photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB3000000)],
                  stops: [0.35, 1.0],
                ),
              ),
            ),

            if (images.length > 1)
              Positioned(
                top: 14,
                right: 14,
                child: _Dots(count: images.length, activeIndex: _page),
              ),

            if (promoBadge != null)
              Positioned(
                top: 14,
                left: 16,
                child: _PromoBadge(label: promoBadge),
              ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    marketLabel(
                      widget.market.key,
                      widget.market.label,
                    ).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (tagline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
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

/// The red "70% OFF"-style tag pinned top-left of a hero/secondary tile —
/// deliberately louder (red, bold, shadowed) than the green "Save X%" pill
/// used on individual offer cards, since this one has to catch the eye from
/// across the whole Dashboard rather than a single card in a scroll list.
class _PromoBadge extends StatelessWidget {
  const _PromoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
