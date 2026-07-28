import 'package:flutter/material.dart';
import 'notification_model.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// A single notification row styled after a native OS push banner (dark
/// card, rounded logo tile, bold headline + timestamp, muted body) so the
/// in-app history reads like the real push the user already recognizes,
/// rather than a generic list item. Tapping is handled entirely by the
/// caller via [onTap] (mark-as-read + navigate).
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  /// `new_offer` notifications carry an optional `data.reason` — "favorite"
  /// when the offer came from a business the user favorited, vs a generic
  /// nearby-city broadcast otherwise. Backend sends the same `type` for
  /// both; this is purely a client-side icon/color distinction (per the
  /// backend note: optional, not required).
  bool get _isFavoriteOffer =>
      notification.type == 'new_offer' &&
      notification.data?['reason'] == 'favorite';

  /// The backend doesn't send a structured status code on `order_status_changed`
  /// notifications, only a canned (always-English) title/body — so this infers
  /// the status from keywords in that raw text. Used both to pick a
  /// status-accurate icon/color (instead of the same generic truck for every
  /// status) and to look up a localized title/body. Returns null for text
  /// that doesn't match any known status, in which case the raw backend text
  /// and the old generic truck icon are used unchanged — see [_iconAndColor]
  /// and [_displayTitle]/[_displayBody].
  NotifOrderStatus? get _orderStatus {
    if (notification.type != 'order_status_changed') return null;
    return classifyOrderStatus(notification.title, notification.body);
  }

  (IconData, Color) get _iconAndColor {
    if (_isFavoriteOffer) {
      return (Icons.directions_run_rounded, AppColors.pink);
    }
    switch (_orderStatus) {
      case NotifOrderStatus.pending:
        return (Icons.hourglass_top_rounded, AppColors.warning);
      case NotifOrderStatus.confirmed:
        return (Icons.check_circle_rounded, AppColors.success);
      case NotifOrderStatus.ready:
        return (Icons.shopping_bag_rounded, AppColors.accent);
      case NotifOrderStatus.completed:
        return (Icons.task_alt_rounded, AppColors.success);
      case NotifOrderStatus.cancelled:
        return (Icons.cancel_rounded, AppColors.error);
      case null:
        break;
    }
    switch (notification.type) {
      case 'new_order':
        return (Icons.receipt_long_rounded, AppColors.success);
      case 'order_status_changed':
        return (Icons.local_shipping_rounded, AppColors.info);
      case 'new_offer':
        return (Icons.local_offer_rounded, AppColors.accent);
      case 'favorite_available':
        return (Icons.notifications_active_rounded, AppColors.success);
      case 'review':
        return (Icons.star_rounded, AppColors.warning);
      case 'system':
        return (Icons.campaign_rounded, AppColors.gray400);
      default:
        return (Icons.notifications_rounded, AppColors.primary);
    }
  }

  /// Prefers a locally-translated title over the backend's raw (always
  /// English) text, same approach `push_notification_service.dart` already
  /// uses for the live push banner — just extended here to the persisted
  /// history list and to `order_status_changed`.
  String get _displayTitle {
    final status = _orderStatus;
    if (status != null) return NotificationsStrings.orderStatusTitle(status);
    switch (notification.type) {
      case 'new_order':
        return 'push_newOrder_title'.tr;
      case 'new_offer':
        return 'push_newOffer_title'.tr;
      case 'favorite_available':
        return NotificationsStrings.favoriteAvailableTitle;
      default:
        return notification.title;
    }
  }

  String get _displayBody {
    final status = _orderStatus;
    if (status != null) {
      return NotificationsStrings.orderStatusBody(
            status,
            rawBody: notification.body,
          ) ??
          notification.body;
    }
    switch (notification.type) {
      case 'new_order':
        return 'push_newOrder_body'.tr;
      case 'new_offer':
        return 'push_newOffer_body'.tr;
      case 'favorite_available':
        return NotificationsStrings.favoriteAvailableBody(
          offerTitle: notification.data?['offerTitle'] as String?,
          businessName: notification.data?['businessName'] as String?,
        );
      default:
        return notification.body;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final (icon, color) = _iconAndColor;
    final title = _displayTitle;
    final body = _displayBody;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread
                ? color.withValues(alpha: 0.45)
                : AppColors.white.withValues(alpha: 0.06),
            width: isUnread ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rounded-square "app icon" tile, like the logo badge on a
            // native push banner.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRelativeTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.white.withValues(alpha: 0.68),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
