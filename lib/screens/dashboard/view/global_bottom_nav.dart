// lib/src/dashboard/view/global_bottom_nav.dart
//
// The one persistent bottom nav for the whole app — Home / Favorites /
// Dashboard / Orders / Profile — built on Flutter's own Material
// NavigationBar so it renders identically everywhere (previously the
// "Dashboard" destination was a hand-rolled raised floating button that
// only appeared while a market was active, making the bar look different
// on the bare Dashboard tiles vs. Food/Cosmetics; it's now a normal,
// always-present destination like the other four).
//
// "Dashboard" sits in the middle only for visual balance — it isn't
// index-adjacent to Favorites/Orders in [onDestinationSelected]'s numbering;
// see the index-mapping comment below.

import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:food_app/controllers/food_controllers/food_customer_controllers/favorites_offer_controller.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_order_controller.dart';
import 'package:food_app/profile_and_orders/orders/controllers/order_controller.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model_ui.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class GlobalBottomNav extends StatelessWidget {
  const GlobalBottomNav({
    super.key,
    required this.selectedIndex,
    required this.activeMarket,
    required this.onDestinationSelected,
    required this.onDashboardTap,
  });

  /// 0=Home, 1=Favorites, 2=Orders, 3=Profile — unaffected by where
  /// "Dashboard" sits visually (see [_visualIndex]/[_fromVisualIndex]).
  final int selectedIndex;

  /// null=Dashboard, 'food', 'cosmetic' — scopes the Orders badge to match
  /// whichever section the user is actually in (see [_orderCount]).
  final String? activeMarket;
  final ValueChanged<int> onDestinationSelected;

  /// Called when the "Dashboard" destination itself is tapped.
  final VoidCallback onDashboardTap;

  /// [selectedIndex] (0-3, skips Dashboard) → the NavigationBar's own
  /// destination index (0-4, Dashboard inserted at 2).
  int _visualIndex(int logical) => logical < 2 ? logical : logical + 1;

  /// The inverse of [_visualIndex] — only meaningful for visual index != 2
  /// (Dashboard), which [_handleSelected] intercepts before calling this.
  int _fromVisualIndex(int visual) => visual < 2 ? visual : visual - 1;

  void _handleSelected(int visual) {
    if (visual == 2) {
      onDashboardTap();
      return;
    }
    onDestinationSelected(_fromVisualIndex(visual));
  }

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesOfferController>();
    final orderController = Get.find<OrderController>();
    final cosmeticOrderController = Get.find<ProductOrderController>();

    return Obx(() {
      final favCount = favoritesController.favoritesCount;
      // Only orders still in progress (not yet delivered/completed/cancelled)
      // should badge the tab — a finished order shouldn't keep nagging.
      // Scoped to whichever section the user is actually in — Food only
      // while in Food, Cosmetic only while in Cosmetic, both combined only
      // on the Dashboard (matching its combined Orders tab, see
      // DashboardOrdersMerger) — not "always both" regardless of context.
      final foodActiveCount = orderController.orders
          .where((o) => o.bucket != OrderBucket.done)
          .length;
      final cosmeticActiveCount = cosmeticOrderController.orders
          .where(
            (o) => !const {
              'completed',
              'delivered',
              'cancelled',
            }.contains(o.status.toLowerCase()),
          )
          .length;
      final orderCount = switch (activeMarket) {
        'food' => foodActiveCount,
        'cosmetic' => cosmeticActiveCount,
        _ => foodActiveCount + cosmeticActiveCount,
      };

      return NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.shellBackground,
          indicatorColor: AppColors.activeTabGold.withValues(alpha: 0.2),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.activeTabGold
                  : AppColors.shellForegroundMuted,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.activeTabGold
                  : AppColors.shellForegroundMuted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _visualIndex(selectedIndex),
          onDestinationSelected: _handleSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: NavigationBarStrings.home,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: favCount > 0,
                label: Text(favCount > 9 ? '9+' : '$favCount'),
                child: const Icon(Icons.favorite_border),
              ),
              selectedIcon: Badge(
                isLabelVisible: favCount > 0,
                label: Text(favCount > 9 ? '9+' : '$favCount'),
                child: const Icon(Icons.favorite),
              ),
              label: NavigationBarStrings.favorites,
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_rounded),
              label: NavigationBarStrings.dashboard,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: orderCount > 0,
                label: Text(orderCount > 9 ? '9+' : '$orderCount'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: orderCount > 0,
                label: Text(orderCount > 9 ? '9+' : '$orderCount'),
                child: const Icon(Icons.receipt_long),
              ),
              label: NavigationBarStrings.orders,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: NavigationBarStrings.profile,
            ),
          ],
        ),
      );
    });
  }
}
