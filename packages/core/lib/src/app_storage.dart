import 'package:hive_ce_flutter/hive_flutter.dart';

/// Single Hive box used as a general key/value store — the replacement for
/// GetStorage. Deliberately mirrors GetStorage's `read<T>`/`write` shape so
/// every call site only needed its import and box constructor swapped.
///
/// Hive stores Dart primitives, Map, and List values natively, so the raw
/// JSON this app caches (see [DataCacheService]) needs no adapters.
///
/// Backs: the language preference (`locale_lang`), avatar URL cache
/// (`avatar_url__*`), the default-bank-account id, the FCM push-token id,
/// and every [DataCacheService] entry (`data_cache__*`).
abstract class AppStorage {
  static const _boxName = 'app_storage';
  static late Box _box;

  /// Opens the box. Must be awaited once, before app startup, alongside
  /// Firebase init (see main.dart).
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static T? read<T>(String key) => _box.get(key) as T?;

  static Future<void> write(String key, dynamic value) => _box.put(key, value);

  static Future<void> remove(String key) => _box.delete(key);

  static bool hasData(String key) => _box.containsKey(key);

  static Iterable<String> getKeys() => _box.keys.cast<String>();
}
