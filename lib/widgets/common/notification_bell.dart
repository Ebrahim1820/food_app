import 'package:flutter/material.dart';
import 'package:food_app/controllers/notification_controller.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:get/get.dart';

/// Bell icon with an unread-count badge, backed by [NotificationController].
/// Tapping opens the shared notifications list screen. Used in both the
/// customer header and the business dashboard top bar — pass [iconColor] to
/// match whichever bar it sits on.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.iconColor = AppColors.ink});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();
    return Obx(() {
      final count = ctrl.unreadCount.value;
      return IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, color: iconColor),
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
        onPressed: () => Get.toNamed(AppRoutes.notifications),
      );
    });
  }
}
