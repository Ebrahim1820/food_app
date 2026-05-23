import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a single shared [FlutterSecureStorage] instance.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

/// Handles reading/writing/deleting the JWT access token securely.
/// Never use SharedPreferences for tokens — this uses the device keychain.
class AuthLocalStorage {
  const AuthLocalStorage(this._storage);

  static const _tokenKey = 'access_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveUserMeta({
    required String userId,
    required String role,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getUserRole() => _storage.read(key: _userRoleKey);

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userRoleKey);
  }
}

final authLocalStorageProvider = Provider<AuthLocalStorage>(
  (ref) => AuthLocalStorage(ref.watch(secureStorageProvider)),
);
