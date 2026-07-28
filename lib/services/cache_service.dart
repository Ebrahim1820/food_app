import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:core/core.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';

/// Clears all app caches and shows a confirmation dialog before doing so.
///
/// What is cleared:
///   1. CachedNetworkImage pixel cache (flutter_cache_manager disk files)
///   2. AppStorage avatar URL entries (keys prefixed with 'avatar_url__')
///
/// What is preserved:
///   • locale_lang  — language preference
///   • Auth tokens  — stored in flutter_secure_storage, untouched here
abstract class CacheService {
  static const _tag = 'CacheService';
  static const _avatarKeyPrefix = 'avatar_url__';

  /// Clears image pixel cache + avatar URL cache.
  /// Returns the freed byte count (approximate, from cache manager).
  static Future<void> clearAll() async {
    // 1 — Remove all avatar URL entries from AppStorage.
    final avatarKeys = AppStorage.getKeys()
        .where((k) => k.startsWith(_avatarKeyPrefix))
        .toList();
    for (final key in avatarKeys) {
      await AppStorage.remove(key);
    }
    AppLogger.info(
      _tag,
      'Removed ${avatarKeys.length} avatar URL cache entries',
    );

    // 2 — Clear cached API data (offers, orders, partner profile).
    await DataCacheService.clearAll();
    AppLogger.info(_tag, 'API data cache cleared');

    // 3 — Clear the CachedNetworkImage / flutter_cache_manager disk store.
    await DefaultCacheManager().emptyCache();
    AppLogger.info(_tag, 'Image pixel cache cleared');
  }

  /// Shows a confirmation dialog then clears the cache.
  /// Call this from any settings screen.
  static Future<void> confirmAndClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          CacheStrings.dialogTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          CacheStrings.dialogContent,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(CacheStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(CacheStrings.clear),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await clearAll();

    AppSnackbar.success(
      CacheStrings.snackTitle,
      CacheStrings.snackBody,
      duration: const Duration(seconds: 3),
    );
  }
}
