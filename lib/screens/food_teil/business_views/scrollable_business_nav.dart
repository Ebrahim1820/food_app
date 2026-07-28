import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_order_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/screens/food_teil/business_views/notification_dot.dart';
import 'package:get/get.dart';

/// Horizontally scrollable bottom nav for the business dashboard on phones.
///
/// The dashboard has 6 tabs (Overview/Orders/Menu/Analytics/Earnings/Reviews)
/// — too many to fit a fixed [NavigationBar] on a narrow phone without
/// dropping one. Reviews used to only be reachable by rotating into the
/// wide/tablet sidebar layout; scrolling keeps every tab reachable in
/// portrait too.
class ScrollableBusinessNav extends StatelessWidget {
  const ScrollableBusinessNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.backgroundColor = AppColors.shellBackground,
    this.selectedColor = AppColors.activeTabGold,
    this.unselectedColor = AppColors.shellForegroundMuted,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Overridable so this can be restyled to match a dark host screen (e.g.
  /// NotificationsScreen) — defaults now match the Perka locked shell
  /// (AppColors.shellBackground + activeTabGold), same brand chrome as the
  /// customer bottom nav, while keeping this widget's own business-specific
  /// tabs (Overview/Orders/Menu/Analytics/Earnings/Reviews) — those don't map
  /// onto the customer's Home/Favorites/Orders/Profile set, so only the
  /// colours are unified here, not the tab content.
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  static const _items = <(IconData, String, int)>[
    (Icons.dashboard_outlined, 'biz_nav_overview', 0),
    (Icons.receipt_long_outlined, 'biz_nav_orders', 1),
    (Icons.restaurant_menu_outlined, 'biz_nav_menu', 2),
    (Icons.bar_chart_outlined, 'biz_nav_analytics', 3),
    (Icons.account_balance_wallet_outlined, 'biz_nav_earnings', 4),
    (Icons.reviews_outlined, 'biz_nav_reviews', 5),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: _items.map((item) {
                final (icon, labelKey, index) = item;
                return _NavItem(
                  icon: index == 1
                      ? const _OrdersIcon(icon: Icons.receipt_long_outlined)
                      : Icon(icon),
                  label: labelKey.tr,
                  selected: selectedIndex == index,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => onSelect(index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Orders icon wrapped with the "new/active orders" [NotificationDot].
class _OrdersIcon extends StatelessWidget {
  const _OrdersIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => NotificationDot(
        show:
            Get.isRegistered<BusinessOrderController>() &&
            Get.find<BusinessOrderController>().hasNewOrActiveOrders,
        child: Icon(icon),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? selectedColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconTheme(
                data: IconThemeData(color: color, size: 22),
                child: icon,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
