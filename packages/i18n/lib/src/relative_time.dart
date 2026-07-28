import 'package:i18n/i18n.dart';
import 'package:intl/intl.dart';

/// Formats [dateTime] relative to now, e.g. "2m ago", "3h ago", "Yesterday",
/// "5d ago", or a plain date once it's more than a week old.
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  final diff = now.difference(local);

  if (diff.inSeconds < 60) return NotificationsStrings.justNow;
  if (diff.inMinutes < 60)
    return NotificationsStrings.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return NotificationsStrings.hoursAgo(diff.inHours);
  if (diff.inDays == 1) return NotificationsStrings.yesterday;
  if (diff.inDays < 7) return NotificationsStrings.daysAgo(diff.inDays);

  return DateFormat('MMM d').format(local);
}
