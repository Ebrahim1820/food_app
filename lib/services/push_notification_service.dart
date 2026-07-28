import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:core/core.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:notification/notification.dart';
import 'package:models/models.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Manages Firebase Cloud Messaging (FCM) for the app.
///
/// Handles three responsibilities:
///   1. Requesting push notification permission from the OS on first launch
///   2. Registering the device token with the backend so the server can send
///      targeted push messages to this device
///   3. Routing incoming messages — showing a banner when the app is open,
///      and navigating to the relevant order when the user taps the notification
///
/// Call [init] once after the user logs in successfully.
class PushNotificationService {
  final _fm = FirebaseMessaging.instance;
  final Dio _dio = Get.find<ApiService>().dio;
  late final OrderService _orderService = OrderService(Get.find<ApiService>());

  static const _tag = 'PushNotificationService';
  static const _kTokenIdKey = 'fcm_device_token_id';
  static const _kPushEnabledKey = 'fcm_push_enabled';

  /// Whether push notifications are enabled for this device.
  /// Reactive so Obx widgets rebuild when toggled.
  late final RxBool pushEnabled;

  // Holds the value the user set while registration was still in flight.
  // Flushed to the server as soon as _registerToken succeeds.
  bool? _pendingEnabled;

  // Subscriptions kept so init() can cancel and re-add them on each login
  // without stacking duplicate listeners.
  StreamSubscription? _onMessageSub;
  StreamSubscription? _onMessageOpenedSub;
  StreamSubscription? _onTokenRefreshSub;

  PushNotificationService() {
    pushEnabled = (AppStorage.read<bool>(_kPushEnabledKey) ?? true).obs;
  }

  /// Initialises FCM: requests permission, registers the device token, and
  /// sets up foreground and tap handlers.
  ///
  /// Safe to call multiple times — FCM deduplicates token registrations.
  Future<void> init() async {
    AppLogger.info(_tag, 'Initialising push notifications');
    final settings = await _fm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.warning(_tag, 'Push notification permission denied by user');
      return;
    }

    // On iOS the APNs token must be available before the FCM token is usable.
    // If it's not ready yet, wait for the next refresh event instead.
    if (Platform.isIOS) {
      final apns = await _fm.getAPNSToken();
      if (apns == null) {
        AppLogger.warning(
          _tag,
          'APNs token not ready — will register on next refresh',
        );
        _fm.onTokenRefresh.listen(_registerToken);
        return;
      }
    }

    final token = await _fm.getToken();
    if (token != null) await _registerToken(token);

    // Cancel previous subscriptions so re-login doesn't stack duplicate listeners.
    await _onTokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();

    _onTokenRefreshSub = _fm.onTokenRefresh.listen(_registerToken);

    // If the app was fully terminated and the user tapped a notification to open it.
    final initial = await _fm.getInitialMessage();
    if (initial != null) _routeMessage(initial);

    // Show an in-app banner when a push arrives while the app is open.
    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);

    // Navigate when the user taps a notification and the app was backgrounded.
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _routeMessage,
    );

    AppLogger.info(_tag, 'Push notification service ready');
  }

  /// Sends the FCM [token] and device platform to the backend.
  ///
  /// Saves the returned device token ID to AppStorage so [setPushEnabled]
  /// can reference it later via PATCH /device-tokens/{id}.
  Future<void> _registerToken(String token) async {
    AppLogger.info(
      _tag,
      'Registering device token (platform=${Platform.isIOS ? "ios" : "android"})',
    );
    try {
      final response = await _dio.post(
        ApiEndpoints.deviceTokens,
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
      AppLogger.info(
        _tag,
        'POST /device-tokens → ${response.statusCode} body=${response.data}',
      );
      // Backend may return a plain numeric "id" or an IRI under "@id" like "/api/device-tokens/5".
      // Try both so we handle either format.
      final rawId = response.data?['id'];
      final rawIri = response.data?['@id'] as String?;
      final id = rawId?.toString() ?? rawIri?.split('/').last;
      if (id != null) {
        await AppStorage.write(_kTokenIdKey, id);
        // Also cache pushEnabled if the backend echoes it back.
        final enabled = response.data?['pushEnabled'];
        if (enabled is bool) {
          pushEnabled.value = enabled;
          await AppStorage.write(_kPushEnabledKey, enabled);
        }
        AppLogger.info(
          _tag,
          'Device token registered (id=$id, pendingEnabled=$_pendingEnabled)',
        );
        // Flush any toggle the user made before registration completed.
        if (_pendingEnabled != null) {
          final pending = _pendingEnabled!;
          _pendingEnabled = null;
          AppLogger.info(
            _tag,
            'Flushing pending pushEnabled=$pending to server',
          );
          await setPushEnabled(pending);
        }
      } else {
        AppLogger.warning(
          _tag,
          'POST /device-tokens returned no id — raw body: ${response.data}',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Device token registration failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Shows a styled in-app banner when a push arrives while the app is in the foreground.
  void _handleForeground(RemoteMessage message) {
    final type = message.data['type'] as String? ?? '';
    AppLogger.info(_tag, 'Foreground push: type=$type');

    // Bump the notification bell badge. Cheap count-only poll — the full
    // history list is only fetched when the user actually opens it.
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshUnreadCount();
    }

    // The banner below is purely visual — it never touched the actual order
    // data, so a business partner sitting on the Overview tab would see the
    // snackbar but the Orders nav dot (and the list itself) stayed stale
    // until the next 30s poll or a tab switch. Refresh right when the push
    // arrives so the dot/list are correct immediately, independent of
    // whichever screen is currently open.
    // force: true is required — fetchOrders() silently no-ops if called
    // within 30s of the last fetch (see _fetchCooldown), which is almost
    // guaranteed here since the poll runs on the same 30s cadence. Without
    // it this call looks like it's working but is a no-op most of the time.
    if (type == 'new_order' && Get.isRegistered<BusinessOrderController>()) {
      Get.find<BusinessOrderController>().fetchOrders(force: true);
    }
    // Same idea for a customer whose own order changes status — refresh
    // their order list — and the detail screen too, if it's open — so it's
    // correct immediately instead of waiting on the next manual
    // pull-to-refresh. Same call the live Mercure `users/{id}/orders`
    // subscription in OrderController triggers.
    if (type == 'order_status_changed' && Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().refreshAfterOrderChange();
    }
    // Same idea for customers browsing the home screen when a new offer
    // goes live nearby — refresh whatever section/category is currently
    // visible so it shows up without a manual pull-to-refresh.
    if (type == 'new_offer' && Get.isRegistered<ProductController>()) {
      Get.find<ProductController>().refreshForNewProduct();
    }
    // A favorited (previously sold-out) offer just came back — refresh the
    // Favorites tab so it's already showing the update if the user switches
    // there, same idea as the new_offer/order_status_changed refreshes above.
    if (type == 'favorite_available' &&
        Get.isRegistered<FavoritesOfferController>()) {
      Get.find<FavoritesOfferController>().loadFavorites();
    }
    // The same offer is very likely also visible (as sold-out) in the Home
    // screen's sections/search results — FoodOfferController only watches
    // the city-wide "new offer" Mercure topic, not per-offer stock, so
    // without this it stays stale until a manual pull-to-refresh even though
    // the Favorites tab already updated. Reuses the exact same refetch the
    // 'new_offer' case above already triggers.
    if (type == 'favorite_available' && Get.isRegistered<ProductController>()) {
      Get.find<ProductController>().refreshForNewProduct();
    }

    // Resolve title and body from local translations so they respect the
    // current app locale instead of relying on the backend's FCM text.
    final String title;
    final String body;
    switch (type) {
      case 'new_offer':
        title = 'push_newOffer_title'.tr;
        body = 'push_newOffer_body'.tr;
      case 'new_order':
        title = 'push_newOrder_title'.tr;
        body = 'push_newOrder_body'.tr;
      case 'favorite_available':
        title = NotificationsStrings.favoriteAvailableTitle;
        body = NotificationsStrings.favoriteAvailableBody(
          offerTitle: message.data['offerTitle'] as String?,
          businessName: message.data['businessName'] as String?,
        );
      case 'order_status_changed':
        // No structured status code on this payload — same raw-text
        // classifier NotificationCard uses for the persisted history, so
        // this live banner respects the app locale too instead of showing
        // the backend's always-English FCM text.
        final rawTitle = message.notification?.title ?? '';
        final rawBody = message.notification?.body ?? '';
        final status = classifyOrderStatus(rawTitle, rawBody);
        if (status != null) {
          title = NotificationsStrings.orderStatusTitle(status);
          body =
              NotificationsStrings.orderStatusBody(status, rawBody: rawBody) ??
              rawBody;
        } else {
          title = rawTitle;
          body = rawBody;
        }
      default:
        title = message.notification?.title ?? '';
        body = message.notification?.body ?? '';
    }

    if (title.isEmpty) return;

    final isOffer = type == 'new_offer';
    final isFavoriteAvailable = type == 'favorite_available';
    // Same client-side distinction as NotificationCard's _isFavoriteOffer —
    // data.reason == 'favorite' is on this raw FCM payload too, not just the
    // persisted /notifications row, so the live toast can match the inbox
    // icon instead of only ever showing the generic offer icon.
    final isFavoriteOffer = isOffer && message.data['reason'] == 'favorite';
    final iconColor = isFavoriteAvailable
        ? AppColors.success
        : isFavoriteOffer
        ? AppColors.pink
        : isOffer
        ? AppColors.primary
        : AppColors.navy;
    final iconData = isFavoriteAvailable
        ? Icons.notifications_active_rounded
        : isFavoriteOffer
        ? Icons.directions_run_rounded
        : isOffer
        ? Icons.local_offer_rounded
        : Icons.notifications_rounded;

    AppSnackbar.show(
      title: title,
      message: body,
      icon: iconData,
      iconColor: iconColor,
      position: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      maxLines: 2,
      onTap: () => _routeMessage(message),
    );
  }

  // Reads the message data and navigates to the right screen.
  Future<void> _routeMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    AppLogger.info(_tag, 'Routing push type=$type data=$data');

    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshUnreadCount();
    }

    // Same reasoning as _handleForeground: tapping the notification opens
    // the one order it's about, but the Orders list/dot behind it was never
    // refreshed on its own — do that here too so returning to the list
    // shows the new order immediately instead of waiting on the next poll.
    // force: true — see the matching comment in _handleForeground.
    if (type == 'new_order' && Get.isRegistered<BusinessOrderController>()) {
      Get.find<BusinessOrderController>().fetchOrders(force: true);
    }

    if (type == 'order_status_changed' && Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().refreshAfterOrderChange();
    }

    if (type == 'favorite_available' &&
        Get.isRegistered<FavoritesOfferController>()) {
      Get.find<FavoritesOfferController>().loadFavorites();
    }

    if (type == 'new_offer' || type == 'favorite_available') {
      // Business partners never navigate to customer product detail — even if
      // the backend mistakenly delivers the notification to a BP device.
      if (Get.isRegistered<BusinessPartnerController>()) {
        AppLogger.info(
          _tag,
          'Skipping $type navigation — user is business partner',
        );
        return;
      }
      // Also guard during active publish to prevent extra routes being pushed.
      if (PublishingOfferGuard.active) {
        AppLogger.info(
          _tag,
          'Skipping $type navigation — offer publish in progress',
        );
        return;
      }
      // Refresh the home screen behind this navigation too, so it's already
      // showing the new/restocked offer when the user backs out of the
      // detail screen instead of still showing it as sold-out.
      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().refreshForNewProduct();
      }
      final offerId = int.tryParse(data['offerId'] ?? '');
      if (offerId == null) return;
      await openOffer(offerId);
      return;
    }

    final orderId = data['orderId'];
    if (orderId != null) {
      AppLogger.info(
        _tag,
        'Notification tapped → navigating to order $orderId',
      );
      await openOrder(orderId);
    }
  }

  /// Fetches offer [offerId] and opens its detail screen. Shared by the FCM
  /// tap handler above and NotificationsScreen (tapping a `new_offer`/
  /// `favorite_available` row in the notification history) so both go
  /// through identical fetch/navigate logic.
  ///
  /// A `favorite_available`/"back in stock" notification can go stale by the
  /// time it's tapped — someone else may have bought the last one again in
  /// the meantime. Rather than open the detail screen on a fetch that may
  /// not read as clearly sold-out to the user, bail out with a toast instead
  /// — same idea for an old `new_offer` alert that's since sold out too.
  Future<void> openOffer(int offerId) async {
    try {
      final res = await _dio.get('${ApiEndpoints.products}/$offerId');
      final offer = ProductModel.fromJson(res.data as Map<String, dynamic>);
      if (offer.isSoldOut) {
        AppLogger.info(
          _tag,
          'openOffer($offerId): already sold out again — showing toast '
          'instead of opening the (potentially stale-looking) detail screen',
        );
        AppSnackbar.warning(
          NotificationsStrings.offerGoneTitle,
          NotificationsStrings.offerGoneBody,
          position: SnackPosition.TOP,
        );
        return;
      }
      Get.to(() => CustomerProductDetailScreen(offer: offer));
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to open offer $offerId from notification',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Opens the order detail screen for [orderId], routing to the business or
  /// customer version depending on who's logged in on this device — a
  /// business partner tapping a new-order notification must land on their
  /// own order detail screen, never the customer dashboard.
  ///
  /// `/orders/$orderId` used to be passed straight to [Get.toNamed], but no
  /// such route is registered in AppPages, so it silently fell through to
  /// the default '/' route (the customer dashboard) for every recipient.
  ///
  /// Shared by the FCM tap handler and NotificationsScreen (tapping an
  /// order-related row in the notification history).
  Future<void> openOrder(String orderId) async {
    final isBusiness = Get.isRegistered<BusinessPartnerController>();
    try {
      final order = await _orderService.getOrderById(orderId);
      if (isBusiness) {
        Get.to(() => BusinessOrderDetailScreen(order: order));
      } else {
        Get.to(() => OrderDetailScreen(order: order));
      }
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to open order $orderId from notification',
        error: e,
        stackTrace: st,
      );
      // Couldn't load the specific order — at least land the user on the
      // right dashboard instead of leaving them wherever the app happened
      // to be, or worse, on the wrong role's dashboard. offAllNamed (not
      // toNamed) — this can fire while already inside that shell, and a
      // push would stack a second instance of it on the navigator.
      Get.offAllNamed(
        isBusiness ? AppRoutes.businessDashboard : AppRoutes.mainNavigation,
      );
    }
  }

  /// Calls PATCH /device-tokens/{id} to update the push-enabled flag for this
  /// device. Updates the local cache on success. Logs the error on failure and
  /// restores the previous local value so the UI can reflect the actual state.
  Future<void> setPushEnabled(bool enabled) async {
    final id = AppStorage.read<String>(_kTokenIdKey);
    if (id == null) {
      // Registration still in flight — store intent and update UI optimistically.
      // _registerToken will flush this to the server once the ID is available.
      _pendingEnabled = enabled;
      pushEnabled.value = enabled;
      await AppStorage.write(_kPushEnabledKey, enabled);
      AppLogger.info(_tag, 'setPushEnabled: queued (token not yet registered)');
      return;
    }
    final previous = pushEnabled.value;
    pushEnabled.value = enabled;
    await AppStorage.write(_kPushEnabledKey, enabled);
    try {
      AppLogger.info(
        _tag,
        'PATCH ${ApiEndpoints.deviceToken(id)} → {pushEnabled: $enabled}',
      );
      final res = await _dio.patch(
        ApiEndpoints.deviceToken(id),
        data: {'pushEnabled': enabled},
      );
      AppLogger.info(
        _tag,
        'PATCH /device-tokens/$id → ${res.statusCode} body=${res.data}',
      );
    } catch (e, st) {
      pushEnabled.value = previous;
      await AppStorage.write(_kPushEnabledKey, previous);
      AppLogger.error(
        _tag,
        'Failed to set pushEnabled → ${(e is DioException) ? '${e.response?.statusCode} ${e.response?.data}' : e}',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
