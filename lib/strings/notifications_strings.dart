import 'package:food_app/utils/currency_formatter.dart';
import 'package:get/get.dart';

/// The five order lifecycle states a `order_status_changed` notification can
/// represent — see [NotificationCard]'s classifier, which infers this from
/// the backend's (always-English, unlocalized) raw title/body since the
/// notification payload doesn't carry a structured status code.
enum NotifOrderStatus { pending, confirmed, ready, completed, cancelled }

/// Infers the lifecycle status from an `order_status_changed`
/// notification's raw (always-English) title+body, since the payload
/// doesn't carry a structured status code. Shared by [NotificationCard]
/// (persisted history) and `PushNotificationService` (live FCM banner) so
/// the two can't drift out of sync the way title/body localization
/// previously did. Returns null for text that doesn't match any known
/// status — caller should fall back to the raw backend text.
NotifOrderStatus? classifyOrderStatus(String title, String body) {
  final text = '$title $body'.toLowerCase();
  if (text.contains('cancel')) return NotifOrderStatus.cancelled;
  if (text.contains('ready')) return NotifOrderStatus.ready;
  if (text.contains('complet') || text.contains('deliver')) {
    return NotifOrderStatus.completed;
  }
  if (text.contains('confirm')) return NotifOrderStatus.confirmed;
  if (text.contains('wait') || text.contains('pending') || text.contains('update')) {
    return NotifOrderStatus.pending;
  }
  return null;
}

abstract class NotificationsStrings {
  static String get appBarTitle => 'notif_appBarTitle'.tr;
  static String get markAllRead => 'notif_markAllRead'.tr;
  static String get emptyTitle => 'notif_emptyTitle'.tr;
  static String get emptySubtitle => 'notif_emptySubtitle'.tr;

  static String get justNow => 'notif_justNow'.tr;
  static String get yesterday => 'notif_yesterday'.tr;

  static String minutesAgo(int minutes) => 'notif_minutesAgo'.trParams({
    'm': CurrencyFormatter.localizeDigits('$minutes'),
  });
  static String hoursAgo(int hours) => 'notif_hoursAgo'.trParams({
    'h': CurrencyFormatter.localizeDigits('$hours'),
  });
  static String daysAgo(int days) => 'notif_daysAgo'.trParams({
    'd': CurrencyFormatter.localizeDigits('$days'),
  });

  static String orderStatusTitle(NotifOrderStatus status) =>
      'notif_orderStatus_${status.name}_title'.tr;

  /// The backend sends exactly one of two things in a cancelled order's
  /// body: this literal canned sentence, or the customer's own free-typed
  /// cancellation reason (see `OrderProcessorState::notifyOrderStatusChanged`
  /// server-side — there's no separate flag distinguishing the two). An
  /// exact match on the canned sentence gets translated; anything else is
  /// free text that can't be translated, so it's shown verbatim — same as a
  /// cancellation reason shown anywhere else in the app.
  static const _backendCannedCancelBody = 'Your order was cancelled.';

  /// [rawBody] is required for [NotifOrderStatus.cancelled] to run the
  /// canned-vs-reason check above; null for every other status just looks
  /// up the plain localized body.
  static String? orderStatusBody(NotifOrderStatus status, {String? rawBody}) {
    if (status == NotifOrderStatus.cancelled) {
      if (rawBody == null || rawBody.trim() == _backendCannedCancelBody) {
        return 'notif_orderStatus_cancelled_body'.tr;
      }
      return rawBody;
    }
    return 'notif_orderStatus_${status.name}_body'.tr;
  }

  static String get favoriteAvailableTitle => 'push_favoriteAvailable_title'.tr;

  /// [offerTitle]/[businessName] come from the notification's `data` payload
  /// (FCM `data.offerTitle`/`data.businessName`, or the persisted inbox
  /// row's `data.offerTitle`/`data.businessName`) so the specific "X at Y is
  /// back" copy can still be built locally per-locale instead of showing the
  /// backend's raw (always-English) text — same reasoning as the rest of
  /// this class. Falls back to a generic message if either is missing
  /// (e.g. an older/malformed payload) rather than rendering "null" or half
  /// a sentence.
  static String favoriteAvailableBody({String? offerTitle, String? businessName}) {
    if (offerTitle == null ||
        offerTitle.isEmpty ||
        businessName == null ||
        businessName.isEmpty) {
      return 'push_favoriteAvailable_body_generic'.tr;
    }
    return 'push_favoriteAvailable_body'.trParams({
      'offerTitle': offerTitle,
      'businessName': businessName,
    });
  }

  /// Shown instead of opening the detail screen when a tapped offer
  /// notification (`new_offer` or `favorite_available`) turns out to already
  /// be sold out again by the time it's tapped.
  static String get offerGoneTitle => 'push_offerGone_title'.tr;
  static String get offerGoneBody => 'push_offerGone_body'.tr;
}
