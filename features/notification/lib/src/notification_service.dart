import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'notification_model.dart';

/// Handles all REST calls for the current user's persisted notification
/// history (GET /notifications and friends) — separate from
/// PushNotificationService, which only handles the live FCM transport.
class NotificationService {
  const NotificationService(this._api);

  final ApiService _api;
  static const _tag = 'NotificationService';
  static const int _defaultPageSize = 20;

  /// Fetches a page of the current user's notifications, newest first.
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int itemsPerPage = _defaultPageSize,
  }) async {
    AppLogger.info(_tag, 'GET notifications page=$page');
    final res = await _api.dio.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': page.toString(),
        'itemsPerPage': itemsPerPage.toString(),
        'order[createdAt]': 'desc',
      },
    );
    final List data = res.data['hydra:member'] as List;
    AppLogger.info(_tag, 'Fetched ${data.length} notification(s)');
    return data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cheap poll for the AppBar badge — avoids fetching/paginating the full
  /// list just to know how many are unread.
  Future<int> getUnreadCount() async {
    final res = await _api.dio.get(ApiEndpoints.notificationsUnreadCount);
    return (res.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(String id) async {
    AppLogger.info(
      _tag,
      'PATCH ${ApiEndpoints.notificationRead(id)} → isRead=true',
    );
    await _api.dio.patch(
      ApiEndpoints.notificationRead(id),
      data: {'isRead': true},
      options: Options(
        headers: {'Content-Type': 'application/merge-patch+json'},
      ),
    );
  }

  Future<void> markAllAsRead() async {
    AppLogger.info(_tag, 'POST ${ApiEndpoints.notificationsReadAll}');
    await _api.dio.post(ApiEndpoints.notificationsReadAll);
  }
}
