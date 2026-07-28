import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Centralised logger for the food app.
///
/// Wraps `dart:developer`'s `log()` so all output is routed through the
/// Flutter DevTools **Logging** tab (filterable by tag and level) instead of
/// being dumped raw to the terminal with `print()`.
///
/// Level semantics (matches `dart:developer` convention):
///   • INFO    (800) — routine diagnostics; debug builds only.
///   • WARNING (900) — unexpected-but-recoverable situations; debug only.
///   • ERROR  (1000) — failures the developer must know about; always logged
///                     in debug and profile builds (never in release).
///
/// Usage:
/// ```dart
/// AppLogger.info('OrderService', 'Fetched ${orders.length} orders');
/// AppLogger.warning('PushService', 'APNs token not ready yet');
/// AppLogger.error('OrderService', 'placeOrder failed',
///     error: e, stackTrace: st);
/// ```
abstract final class AppLogger {
  static const int _levelInfo = 800;
  static const int _levelWarning = 900;
  static const int _levelError = 1000;

  /// Routine diagnostic information. Only active in debug builds.
  static void info(String tag, String message) {
    if (kDebugMode) {
      dev.log(message, name: tag, level: _levelInfo);
      debugPrint('[INFO] [$tag] $message');
    }
  }

  /// Unexpected but non-fatal situation. Only active in debug builds.
  static void warning(String tag, String message) {
    if (kDebugMode) {
      dev.log(message, name: tag, level: _levelWarning);
      debugPrint('[WARN] [$tag] $message');
    }
  }

  /// A failure the developer must investigate. Logged in debug and profile
  /// builds but suppressed in release so no stack traces leak to end users.
  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kReleaseMode) {
      dev.log(
        message,
        name: tag,
        level: _levelError,
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[ERROR] [$tag] $message${error != null ? '\n  $error' : ''}');
    }
  }
}
