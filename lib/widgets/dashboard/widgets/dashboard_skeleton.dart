import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// Lightweight pulsing placeholder shown while the Dashboard's first fetch is
/// in flight and there's no cached data to show yet. No shimmer package in
/// this project — a simple opacity tween reads as "loading" just as well.
class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _block({double? width, required double height, double radius = 16}) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(width: 160, height: 14, radius: 6),
          const SizedBox(height: 8),
          _block(width: 120, height: 22, radius: 6),
          const SizedBox(height: 20),
          _block(height: 52, radius: 16),
          const SizedBox(height: 22),
          _block(height: 170, radius: 24),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _block(height: 130)),
              const SizedBox(width: 12),
              Expanded(child: _block(height: 130)),
            ],
          ),
        ],
      ),
    );
  }
}
