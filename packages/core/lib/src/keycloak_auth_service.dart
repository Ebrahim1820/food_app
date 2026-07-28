import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_constants.dart';
import 'app_logger.dart';
import 'app_routes.dart';

/// Handles login / logout / token refresh against Keycloak using the
/// Direct Access Grant ("password") flow, so the app uses its OWN in-app
/// login form and NEVER shows Keycloak's hosted login page.
///
/// Trade-off: this flow is less secure than the browser code flow and gives
/// up SSO / MFA / social login / forgot-password. Fine for a first-party app.
///
/// The Flutter app is a PUBLIC client, so there is NO client secret here.
/// The `food-api-mobile` client MUST have "Direct access grants" enabled.
class KeycloakAuthService {
  KeycloakAuthService();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // A bare Dio with NO interceptor — auth calls must not be intercepted by
  // the AuthInterceptor (that would cause infinite loops).
  final Dio _authDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Mutex for token refresh: if multiple requests hit expiry simultaneously
  // they all share one refresh call rather than each firing their own.
  // Without this, concurrent refreshes send the same refresh_token to Keycloak;
  // when rotation is enabled the second one fails, triggering logout(localOnly)
  // which deletes the tokens that the first refresh just stored.
  Completer<String?>? _refreshCompleter;

  // Host comes from ApiConstants (one place to change). Must match KC_HOSTNAME.
  static String get baseUrl => ApiConstants.keycloakBaseUrl;
  static const String realm = ApiConstants.realm;
  static const String clientId = ApiConstants.clientId;

  // Space-separated scopes. (No 'offline_access' to avoid the offline-token
  // role requirement; a normal refresh token is still returned.)
  static const String scope = 'openid profile email roles';

  String get _tokenEndpoint =>
      '$baseUrl/realms/$realm/protocol/openid-connect/token';
  String get _logoutEndpoint =>
      '$baseUrl/realms/$realm/protocol/openid-connect/logout';

  // Storage keys
  static const _kAccessToken = 'kc_access_token';
  static const _kRefreshToken = 'kc_refresh_token';
  static const _kIdToken = 'kc_id_token';

  /// Reads [key] from secure storage, retrying once after a short delay if
  /// the first read comes back empty.
  ///
  /// Guards against a specific hot-restart flakiness: Flutter's "Restarted
  /// application" reinitializes the Dart VM and re-runs plugin registration,
  /// but the native host process (and its plugin channels) doesn't restart.
  /// The very first secure-storage read fired right after a hot restart can
  /// occasionally race that channel rebinding and come back null even though
  /// a token is genuinely stored — which getValidAccessToken()/isLoggedIn()
  /// would otherwise read as "logged out" and AuthInterceptor would force a
  /// logout to the login screen for a user who never actually logged out.
  /// A genuinely absent key still reads null on the retry, so this never
  /// masks a real logout — it only costs one extra read (plus a short delay)
  /// on the already-rare "no token found" path.
  Future<String?> _readWithRetry(String key) async {
    final first = await _storage.read(key: key);
    if (first != null) return first;
    await Future.delayed(const Duration(milliseconds: 250));
    return _storage.read(key: key);
  }

  /// Logs in with username/password collected by YOUR in-app form.
  /// Returns the access token on success, or null on invalid credentials.
  Future<String> login(String username, String password) async {
    try {
      final res = await _authDio.post(
        _tokenEndpoint,
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: {
          'grant_type': 'password',
          'client_id': clientId,
          'username': username,
          'password': password,
          'scope': scope,
        },
      );

      final data = res.data as Map;
      final token = data['access_token'] as String?;
      if (token == null) throw Exception('server_unreachable');

      await _persistTokens(
        accessToken: token,
        refreshToken: data['refresh_token'] as String?,
        idToken: data['id_token'] as String?,
      );
      return token;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      AppLogger.warning(
        'KeycloakAuthService',
        'Login rejected: HTTP $status | type=${e.type} | msg=${e.message}',
      );
      if (status == 401 || status == 400)
        throw Exception('incorrect_credentials');
      throw Exception('server_unreachable');
    }
  }

  /// Returns a valid access token, refreshing it only when it has expired.
  /// Returns null if the user is not logged in and cannot be refreshed.
  Future<String?> getValidAccessToken() async {
    final stored = await _readWithRetry(_kAccessToken);
    if (stored != null && stored.isNotEmpty) {
      try {
        final parts = stored.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          );
          final claims = json.decode(payload) as Map<String, dynamic>;
          final exp = claims['exp'] as int?;
          if (exp != null) {
            final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            if (expiresAt.isAfter(
              DateTime.now().add(const Duration(seconds: 30)),
            )) {
              return stored;
            }
          }
        }
      } catch (e) {
        AppLogger.warning('KeycloakAuthService', 'Token decode error: $e');
      }
    }

    // Token is missing or about to expire — need to refresh.
    // Mutex: if another call already started a refresh, wait for its result
    // rather than firing a second refresh with the same refresh_token.
    // Duplicate refreshes cause problems when Keycloak rotation is enabled:
    // the losing call's DioException handler calls logout(localOnly:true)
    // which deletes the tokens the winning call just stored.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    // Claim the mutex synchronously — no `await` between the check above and
    // this assignment — so a concurrent call can't also slip past that check
    // before we've claimed it. (The previous version read the refresh token
    // via `await` first and only set `_refreshCompleter` afterwards, leaving
    // a window where two concurrent calls could both see it as null, each
    // overwrite the field with their own Completer, and the loser then hit
    // `_refreshCompleter!` after the winner's `finally` had already nulled it
    // out — a "Null check operator used on a null value" crash inside the
    // Dio interceptor that left the original request's Future pending
    // forever.) Every await below completes/reads the local `completer`, not
    // the (possibly reassigned) `_refreshCompleter` field, so this call
    // always resolves its own future regardless of what else races it.
    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _readWithRetry(_kRefreshToken);
      if (refreshToken == null) {
        completer.complete(null);
        return null;
      }

      final res = await _authDio.post(
        _tokenEndpoint,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        data: {
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'refresh_token': refreshToken,
        },
      );
      final data = res.data as Map;
      await _persistTokens(
        accessToken: data['access_token'] as String?,
        refreshToken: (data['refresh_token'] as String?) ?? refreshToken,
        idToken: data['id_token'] as String?,
      );
      final newToken = data['access_token'] as String?;
      completer.complete(newToken);
      return newToken;
    } on DioException catch (e) {
      // Only a genuine invalid_grant (HTTP 400/401 from Keycloak) means the
      // refresh token is dead and the user must re-login.
      // Network timeouts, connection errors, etc. are transient — do NOT
      // delete the stored tokens or the user gets kicked out on every hiccup.
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        await logout(localOnly: true);
      }
      completer.complete(null);
      return null;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  /// Forces a token refresh against Keycloak, ignoring whether the current
  /// access token's [exp] claim looks valid. Use this after a 401 from the API
  /// to handle cases where the server rejects a token that appears valid
  /// client-side (clock skew, revocation, key rotation).
  Future<String?> forceRefreshToken() async {
    await _storage.delete(key: _kAccessToken);
    return getValidAccessToken();
  }

  /// Ends the Keycloak session (server-side) and clears local tokens.
  Future<void> logout({bool localOnly = false}) async {
    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (!localOnly && refreshToken != null) {
      try {
        await _authDio.post(
          _logoutEndpoint,
          options: Options(contentType: Headers.formUrlEncodedContentType),
          data: {'client_id': clientId, 'refresh_token': refreshToken},
        );
      } catch (_) {
        // ignore network errors during logout
      }
    }
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kIdToken);
  }

  Future<bool> isLoggedIn() async =>
      (await _readWithRetry(_kRefreshToken)) != null ||
      (await _readWithRetry(_kAccessToken)) != null;

  /// Returns the Keycloak `sub` UUID from the current valid token.
  /// Uses the same token source as the API interceptor — guaranteed to match
  /// what the backend sees as the caller's identity.
  Future<String?> getUserId() async {
    final token = await getValidAccessToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = json.decode(payload) as Map<String, dynamic>;
      final sub = claims['sub'] as String?;
      return (sub != null && sub.isNotEmpty) ? sub : null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ROLES (for role-based redirect)
  // ---------------------------------------------------------------------------

  /// Reads the realm roles baked inside an access token. A JWT has 3 parts
  /// separated by dots: header.payload.signature. The roles live in the
  /// payload under realm_access.roles. We just base64-decode the payload —
  /// no signature check needed here (the API already verifies the token).
  List<String> getRolesFromToken(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return const [];
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = json.decode(payload) as Map<String, dynamic>;
      final realmAccess = map['realm_access'] as Map<String, dynamic>?;
      final roles = realmAccess?['roles'] as List<dynamic>?;
      return roles?.map((r) => r.toString()).toList() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Roles of the currently stored token (empty if logged out).
  Future<List<String>> currentRoles() async {
    final token = await _storage.read(key: _kAccessToken);
    if (token == null) return const [];
    return getRolesFromToken(token);
  }

  /// Decides which screen to land on, based on the user's roles.
  /// Admin → admin dashboard; everyone else (including business
  /// partners/staff) → the market-tile Dashboard.
  ///
  /// Business partners/staff used to go straight to a specific market's
  /// business screen (Food's businessDashboard) — that stopped making sense
  /// once a business could operate in more than one market (or a market
  /// other than Food): there's no single "the" business screen to jump to
  /// anymore. They land on the Dashboard like everyone else and pick a
  /// market tile; DashboardController.onTileTap already routes each tap to
  /// the right business/customer screen based on which market(s) this
  /// account actually operates in.
  String homeRouteForRoles(List<String> roles) {
    if (roles.contains('ROLE_ADMIN')) return AppRoutes.adminDashboard;
    return AppRoutes.dashboard;
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------
  Future<void> _persistTokens({
    String? accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    if (accessToken != null) {
      await _storage.write(key: _kAccessToken, value: accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    }
    if (idToken != null) {
      await _storage.write(key: _kIdToken, value: idToken);
    }
  }
}
