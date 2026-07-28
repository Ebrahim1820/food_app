import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Cart icon with an item-count badge, backed by [CartController] — the
/// persistent way back into the cart from anywhere, mirroring
/// [NotificationBell]'s exact look (icon + badge in the shell AppBar).
/// Shown only on customer shells that actually have a cart (see
/// `ShellAppBar.showCartButton`/`DashboardShell.showCartButton` — business
/// and admin dashboards don't pass this).
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key, this.iconColor = AppColors.ink});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Obx(() {
      final count = cart.itemCount;
      return IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.shopping_cart_outlined, color: iconColor),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () => Get.to(() => const CartScreen()),
      );
    });
  }
}
