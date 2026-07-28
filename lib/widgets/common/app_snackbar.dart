import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';

enum AppSnackbarType { success, error, warning, info, neutral }

/// Single source of truth for every toast/snackbar in the app.
/// Background is a fixed dark "surface" so the app has one consistent,
/// professional look; only the icon/accent color changes per [AppSnackbarType].
/// Title/message colors are chosen for contrast against [backgroundColor]
/// automatically, so a lighter override never produces invisible text.
class AppSnackbar {
  AppSnackbar._();

  static const Color _defaultBackground = AppColors.gray800;

  static void show({
    required String title,
    required String message,
    AppSnackbarType type = AppSnackbarType.neutral,
    IconData? icon,
    Color? iconColor,
    Color backgroundColor = _defaultBackground,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 4),
    int maxLines = 3,
    VoidCallback? onTap,
  }) {
    final resolvedIconColor = iconColor ?? _iconColorFor(type);
    final titleColor = _titleColorFor(backgroundColor);
    final messageColor = _messageColorFor(backgroundColor);

    Get.snackbar(
      title,
      message,
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: resolvedIconColor.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon ?? _iconFor(type), color: resolvedIconColor, size: 22),
      ),
      shouldIconPulse: false,
      titleText: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          height: 1.2,
        ),
      ),
      messageText: message.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                message,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: messageColor, fontSize: 13, height: 1.4),
              ),
            )
          : const SizedBox.shrink(),
      backgroundColor: backgroundColor,
      snackPosition: position,
      duration: duration,
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      boxShadows: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 26 / 255),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
      animationDuration: const Duration(milliseconds: 350),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      onTap: onTap == null ? null : (_) => onTap(),
    );
  }

  static void success(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) => show(
    title: title,
    message: message,
    type: AppSnackbarType.success,
    position: position,
    duration: duration,
    onTap: onTap,
  );

  static void error(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) => show(
    title: title,
    message: message,
    type: AppSnackbarType.error,
    position: position,
    duration: duration,
    onTap: onTap,
  );

  static void warning(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) => show(
    title: title,
    message: message,
    type: AppSnackbarType.warning,
    position: position,
    duration: duration,
    onTap: onTap,
  );

  static void info(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) => show(
    title: title,
    message: message,
    type: AppSnackbarType.info,
    position: position,
    duration: duration,
    onTap: onTap,
  );

  static IconData _iconFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_rounded;
      case AppSnackbarType.error:
        return Icons.error_rounded;
      case AppSnackbarType.warning:
        return Icons.warning_rounded;
      case AppSnackbarType.info:
        return Icons.info_rounded;
      case AppSnackbarType.neutral:
        return Icons.notifications_rounded;
    }
  }

  static Color _iconColorFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return AppColors.success;
      case AppSnackbarType.error:
        return AppColors.error;
      case AppSnackbarType.warning:
        return AppColors.warning;
      case AppSnackbarType.info:
        return AppColors.info;
      case AppSnackbarType.neutral:
        return AppColors.white;
    }
  }

  static Color _titleColorFor(Color background) =>
      background.computeLuminance() > 0.5 ? AppColors.ink : AppColors.white;

  static Color _messageColorFor(Color background) =>
      background.computeLuminance() > 0.5
      ? AppColors.gray600
      : AppColors.gray300;
}
