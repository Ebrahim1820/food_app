import 'dart:convert';

import 'app_storage.dart';

/// Stores and retrieves raw API JSON in [AppStorage] (Hive) so controllers
/// can show data immediately on launch before the network request completes.
///
/// Keys are namespaced with [_prefix] to avoid collisions with other storage.
/// Each entry is: { 'ts': epochMs, 'data': <raw json> }
///
/// Entries older than [maxAge] (5 minutes by default) are treated as if they
/// don't exist at all — [load] returns null so the caller falls back to its
/// normal loading-spinner path instead of showing stale data.
///
/// Usage:
///   // Save after a successful API call:
///   await DataCacheService.save('partner', partner.toJson());
///
///   // Load on next launch (returns null if nothing cached, or it's stale):
///   final cached = DataCacheService.load('partner',
///       (json) => BusinessPartnerModel.fromJson(json));
abstract class DataCacheService {
  static const _prefix = 'data_cache__';

  static const Duration defaultMaxAge = Duration(minutes: 5);

  /// Saves [json] (a Map or List) under [key].
  static Future<void> save(String key, dynamic json) async {
    await AppStorage.write('$_prefix$key', {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'data': json,
    });
  }

  /// Reads the cached value for [key] and runs [parse] on it.
  /// Returns null if nothing is stored, parsing fails, or the entry is older
  /// than [maxAge].
  static T? load<T>(
    String key,
    T Function(dynamic json) parse, {
    Duration maxAge = defaultMaxAge,
  }) {
    try {
      final raw = AppStorage.read<Map>('$_prefix$key');
      if (raw == null) return null;

      final ts = raw['ts'] as int?;
      if (ts == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > maxAge.inMilliseconds) return null;

      // Hive returns nested maps/lists as Map<dynamic, dynamic> rather than
      // Map<String, dynamic> — round-trip through JSON so `parse` (which
      // expects real JSON types, same as every API response) gets what it
      // expects, exactly like the old GetStorage-backed version did.
      final data = jsonDecode(jsonEncode(raw['data']));
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// True if a non-expired cache entry exists for [key].
  static bool exists(String key, {Duration maxAge = defaultMaxAge}) =>
      load<Object?>(key, (json) => json, maxAge: maxAge) != null;

  /// Removes the cache entry for [key].
  static Future<void> remove(String key) => AppStorage.remove('$_prefix$key');

  /// Removes all data cache entries (called from CacheService.clearAll).
  static Future<void> clearAll() async {
    final keys = AppStorage.getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final k in keys) {
      await AppStorage.remove(k);
    }
  }
}
