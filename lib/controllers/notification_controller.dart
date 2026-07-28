import 'dart:async';

import 'package:dio/dio.dart';
import 'package:food_app/models/notification_model.dart';
import 'package:food_app/services/notification_service.dart';
import 'package:food_app/utils/app_logger.dart';
import 'package:get/get.dart';

/// Single source of truth for the notification bell: unread badge count and
/// the paginated history list shown on NotificationsScreen. Used by both the
/// customer and business-partner AppBars.
///
/// [unreadCount] is meant to be bumped cheaply and often — e.g. from
/// PushNotificationService whenever a push arrives — without paying for a
/// full list refetch each time. The list itself is only fetched when the
/// user actually opens NotificationsScreen.
class NotificationController extends GetxController {
  NotificationController(this._service);

  final NotificationService _service;
  static const _tag = 'NotificationController';
  static const int _pageSize = 20;

  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final loadingMore = false.obs;
  final hasMore = true.obs;
  int _currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    refreshUnreadCount();
  }

  /// Loads page 1 (or the next page when [loadMore]) of the notification
  /// history. Called when NotificationsScreen opens and on pull-to-refresh /
  /// infinite scroll.
  Future<void> fetchNotifications({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore.value || loadingMore.value) return;
      loadingMore.value = true;
    } else {
      isLoading.value = true;
      _currentPage = 1;
      hasMore.value = true;
    }

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final result = await _service.getNotifications(
        page: page,
        itemsPerPage: _pageSize,
      );
      if (loadMore) {
        notifications.addAll(result);
      } else {
        notifications.assignAll(result);
        // Keeps the "Mark all read" button (visible only when unreadCount >
        // 0) in sync with what this fetch just showed — previously only
        // updated at controller creation or when a push arrived, so it could
        // sit stale (e.g. showing 0 / hiding the button) relative to a list
        // that was just freshly (re)loaded.
        unawaited(refreshUnreadCount());
      }
      _currentPage = page;
      hasMore.value = result.length >= _pageSize;
    } catch (e, s) {
      AppLogger.error(
        _tag,
        'fetchNotifications failed',
        error: e,
        stackTrace: s,
      );
    } finally {
      isLoading.value = false;
      loadingMore.value = false;
    }
  }

  /// Cheap poll for the AppBar badge — call this whenever a push/Mercure
  /// event suggests something new happened, without fetching the full list.
  Future<void> refreshUnreadCount() async {
    try {
      unreadCount.value = await _service.getUnreadCount();
    } on DioException catch (e) {
      // Session expired or network down are expected flow-control states.
      // The AuthInterceptor already handles redirecting to login if session_expired.
      if (e.error == 'session_expired' || e.error == 'network_unavailable') {
        return;
      }

      AppLogger.error(
        _tag,
        'refreshUnreadCount HTTP failure: ${e.response?.statusCode}',
        error: e,
      );
    } catch (e, s) {
      AppLogger.error(
        _tag,
        'refreshUnreadCount unexpected error',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Marks one notification read with an optimistic update, rolled back on
  /// failure — same pattern as BusinessPartnerController's toggles.
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final idx = notifications.indexWhere((n) => n.id == notification.id);
    if (idx != -1) notifications[idx] = notification.copyWith(isRead: true);
    if (unreadCount.value > 0) unreadCount.value--;

    try {
      await _service.markAsRead(notification.id);
    } catch (e, s) {
      AppLogger.error(
        _tag,
        'markAsRead(${notification.id}) failed',
        error: e,
        stackTrace: s,
      );
      if (idx != -1) notifications[idx] = notification;
      unreadCount.value++;
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount.value == 0) return;

    final previous = notifications.toList();
    final previousUnread = unreadCount.value;
    notifications.assignAll(
      notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
    unreadCount.value = 0;

    try {
      await _service.markAllAsRead();
    } catch (e, s) {
      AppLogger.error(_tag, 'markAllAsRead failed', error: e, stackTrace: s);
      notifications.assignAll(previous);
      unreadCount.value = previousUnread;
    }
  }
}
