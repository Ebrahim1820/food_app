// Business — Impact Tracker screen.
//
// Full-screen breakdown of the environmental impact of the business's
// completed orders (meals rescued, CO2/water/land saved). Reached from the
// ImpactHeroCard on the dashboard Overview tab.
//
// BusinessOrderController.orders is already the business's complete order
// list (no pagination on that endpoint), so unlike the customer screen no
// extra page-loading is needed here — it just reads the reactive list.

import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_order_controller.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/screens/food_teil/shared_customer_and_business_utils/impact_calculator.dart';
import 'package:food_app/screens/food_teil/shared_customer_and_business_widget/impact_tracker_widget.dart';
import 'package:get/get.dart';

class BusinessImpactScreen extends StatelessWidget {
  const BusinessImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderCtrl = Get.find<BusinessOrderController>();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.gray50,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: Text(
          ImpactStrings.screenTitleBusiness,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: Obx(() {
        final loading = orderCtrl.isLoading.value && orderCtrl.orders.isEmpty;
        final stats = ImpactCalculator.fromOrders(orderCtrl.orders);

        return RefreshIndicator(
          onRefresh: () => orderCtrl.fetchOrders(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBanner(stats: stats, isLoading: loading),
                const SizedBox(height: 20),
                if (!loading && stats.isEmpty)
                  ImpactEmptyState(
                    subtitle: ImpactStrings.emptySubtitleBusiness,
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

  const _HeroBanner({required this.stats, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2044), AppColors.successDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(right: -30, top: -30, child: _circle(120, 0.07)),
          Positioned(left: -30, bottom: -40, child: _circle(140, 0.05)),
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
                ImpactStrings.heroBannerSubtitleBusiness,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              if (!isLoading) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${CurrencyFormatter.localizeDigits(stats.ordersRescued.toString())} ${ImpactStrings.statOrders}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
