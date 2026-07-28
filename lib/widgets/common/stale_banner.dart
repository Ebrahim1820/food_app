import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// Shown at the top of a screen when the controller is displaying cached data
/// from the previous session while a fresh network request is in flight.
///
/// Usage:
///   Obx(() => controller.isFromCache.value
///       ? StaleBanner(onRefresh: controller.fetchXxx)
///       : const SizedBox.shrink())
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8E1),
      child: InkWell(
        onTap: onRefresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 16,
                color: Color(0xFF856404),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Showing saved data · Tap to refresh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF856404),
                  ),
                ),
              ),
              const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Color(0xFF856404),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when a fetch fails and there is no cached data to fall back on.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 52,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
