// Customer — Impact Tracker screen.
//
// Full-screen breakdown of the environmental impact of the customer's
// rescued orders (meals rescued, CO2/water/land saved) — TGTG's Profile
// retention hook. Reached from the ImpactHeroCard on CustomerProfileScreen.

import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/screens/food_teil/shared_customer_and_business_utils/impact_calculator.dart';
import 'package:food_app/screens/food_teil/shared_customer_and_business_widget/impact_tracker_widget.dart';
import 'package:get/get.dart';

class CustomerImpactScreen extends StatefulWidget {
  const CustomerImpactScreen({super.key});

  @override
  State<CustomerImpactScreen> createState() => _CustomerImpactScreenState();
}

class _CustomerImpactScreenState extends State<CustomerImpactScreen> {
  final _orderCtrl = Get.find<OrderController>();
  final _loadingAll = true.obs;

  @override
  void initState() {
    super.initState();
    _orderCtrl.loadAllOrders().whenComplete(() => _loadingAll.value = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: Text(
          ImpactStrings.screenTitleCustomer,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: Obx(() {
        final loading = _loadingAll.value;
        final stats = ImpactCalculator.fromOrders(_orderCtrl.orders);

        return RefreshIndicator(
          onRefresh: () async {
            _loadingAll.value = true;
            await _orderCtrl.loadAllOrders();
            _loadingAll.value = false;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBanner(
                  stats: stats,
                  isLoading: loading,
                  subtitle: ImpactStrings.heroBannerSubtitleCustomer,
                ),
                const SizedBox(height: 20),
                if (!loading && stats.isEmpty)
                  ImpactEmptyState(
                    subtitle: ImpactStrings.emptySubtitleCustomer,
                  )
                else ...[
                  ImpactStatGrid(stats: stats),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: ImpactStrings.equivalencesTitle,
                    child: ImpactEquivalencesList(stats: stats),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  ImpactStrings.footerNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final ImpactStats stats;
  final bool isLoading;
  final String subtitle;

  const _HeroBanner({
    required this.stats,
    required this.isLoading,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.headerGradientStart],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(right: -30, top: -30, child: _circle(120, 0.08)),
          Positioned(left: -30, bottom: -40, child: _circle(140, 0.06)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 34),
              const SizedBox(height: 10),
              isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    )
                  : Text(
                      CurrencyFormatter.localizeDigits(
                        stats.mealsRescued.round().toString(),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
              const SizedBox(height: 6),
              Text(
                ImpactStrings.statMeals,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
