import 'package:i18n/i18n.dart';

class HelperMethods {
  /// Formats full date & time.
  ///
  /// Example:
  /// 28/05/2026 18:30
  static String formatDateTime(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  /// Formats compact readable date & time.
  ///
  /// Example:
  /// 28 May 18:30
  static String formatDateTimeShort(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return "$day $month $hour:$minute";
  }

  /// Formats only time.
  ///
  /// Example:
  /// 18:30
  static String formatTimeOnly(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  /// Creates user-friendly pickup label based only on end time (legacy, prefer formatPickupWindow).
  static String formatPickupLabel(DateTime date) {
    final now = DateTime.now();
    final today =
        now.day == date.day && now.month == date.month && now.year == date.year;
    final tomorrow =
        now.add(const Duration(days: 1)).day == date.day &&
        now.month == date.month &&
        now.year == date.year;
    if (today) return 'Pick up · today before ${formatTimeOnly(date)}';
    if (tomorrow) return 'Pick up · tomorrow before ${formatTimeOnly(date)}';
    return '${date.day}/${date.month} · ${formatTimeOnly(date)}';
  }

  /// Creates a user-friendly pickup window label using both start and end times.
  ///
  /// Same day:  "Today · 14:00 – 18:00"
  ///            "Tomorrow · 14:00 – 18:00"
  ///            "Mon 30 Jul · 14:00 – 18:00"
  /// Multi-day: "30 Jul 14:00 – 1 Aug 18:00"
  static String formatPickupWindow(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Available anytime'; // Or return empty string ''
    }
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${_dayPrefix(start)} · ${formatTimeOnly(start)} – ${formatTimeOnly(end)}';
    }
    return '${start.day} ${_monthAbbr(start.month)} ${formatTimeOnly(start)} – ${end.day} ${_monthAbbr(end.month)} ${formatTimeOnly(end)}';
  }

  static String _dayPrefix(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tom = now.add(const Duration(days: 1));
    if (date.year == tom.year &&
        date.month == tom.month &&
        date.day == tom.day) {
      return 'Tomorrow';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]} ${date.day} ${_monthAbbr(date.month)}';
  }

  static String _monthAbbr(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  /// Capitalizes first letter of text.
  ///
  /// Example:
  /// active -> Active
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1);
  }

  /// Checks whether offer end time has passed.
  ///
  /// Example:
  /// true  -> expired
  /// false -> still active
  static bool isExpired(DateTime endTime) {
    return DateTime.now().isAfter(endTime);
  }

  static String formatPrice(dynamic price) {
    final amount = double.tryParse(price?.toString() ?? '') ?? 0;
    return CurrencyFormatter.format(amount);
  }

  static String formatDistance(double distance) {
    return "${distance.toStringAsFixed(1)} km";
  }
}
