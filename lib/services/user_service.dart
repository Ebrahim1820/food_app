import 'package:dio/dio.dart';
import 'package:food_app/constants/api_endpoints.dart';
import 'package:food_app/models/mercure_credentials_model.dart';
import 'package:food_app/models/user_model.dart';
import 'package:food_app/network/api_service.dart';
import 'package:food_app/utils/app_logger.dart';

/// Handles REST calls for the `/users` resource.
///
/// Used by the admin panel to list and manage customer accounts.
/// Regular customers use [BusinessPartnerService] to read their own profile
/// and [AddressService] for their saved delivery addresses.
class UserService {
  const UserService(this._api);

  final ApiService _api;
  static const _tag = 'UserService';

  /// Fetches all registered users (admin use only).
  ///
  /// Returns an empty list on failure so the admin screen can still render
  /// without crashing when the endpoint is temporarily unavailable.
  Future<List<UserModel>> getUsers() async {
    AppLogger.info(_tag, 'GET ${ApiEndpoints.users}');
    try {
      final response = await _api.dio.get(ApiEndpoints.users);
      final List usersJson = response.data['hydra:member'] as List;
      AppLogger.info(_tag, 'Fetched ${usersJson.length} user(s)');
      return usersJson
          .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getUsers failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      return [];
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getUsers unexpected error',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Asks the backend to send a new verification email to [email].
  ///
  /// The endpoint always returns 200 whether or not the account exists (security).
  /// Throws [DioException] only on genuine network / server failures.
  Future<void> resendVerificationEmail(String email) async {
    AppLogger.info(_tag, 'POST /resend-verification for $email');
    try {
      await _api.dio.post(
        '/resend-verification',
        data: {'email': email},
        options: Options(
          // Public endpoint — no auth header needed (and sending a stale token
          // would cause a 401 retry loop). The base Accept header is overridden
          // because this endpoint returns plain JSON, not JSON-LD.
          extra: {'noAuth': true},
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );
      AppLogger.info(_tag, 'resendVerificationEmail sent for $email');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'resendVerificationEmail failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Lightweight call to check whether the current user has verified their email.
  /// Uses the authenticated /users/me endpoint — only valid when a token exists.
  /// Returns `null` on any error so callers can preserve the last known value.
  Future<bool?> fetchIsVerified() async {
    try {
      final response = await _api.dio.get('/users/me');
      final data = response.data as Map<String, dynamic>;
      return (data['isVerified'] as bool?) ?? false;
    } catch (_) {
      return null;
    }
  }

  /// Public endpoint — no auth token required.
  /// Used on the email-verification notice screen (right after registration,
  /// before the user has a valid token) to poll for verification without
  /// risking a stale-token false positive.
  ///
  /// Backend route needed (Symfony example):
  ///   GET /api/check-verification?email=x  →  {"isVerified": true|false}
  ///   (public, rate-limited — no auth guard)
  Future<bool> checkVerificationByEmail(String email) async {
    AppLogger.info(_tag, 'GET /check-verification for $email');
    try {
      final response = await _api.dio.get(
        '/check-verification',
        queryParameters: {'email': email},
        options: Options(
          extra: {'noAuth': true},
          headers: {'Accept': 'application/json'},
        ),
      );
      final data = response.data;
      if (data is Map) {
        return (data['isVerified'] as bool?) ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the full profile of the currently authenticated user.
  /// Used to pre-fill edit-profile fields that are not in the JWT (lastName, phone).
  Future<UserModel> fetchMe() async {
    AppLogger.info(_tag, 'GET /users/me');
    try {
      final response = await _api.dio.get('/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchMe failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// GET /me/mercure-token — short-lived SSE credential (JWT + a `topics`
  /// array) for subscribing to this user's private Mercure topics. Every
  /// user gets `users/{id}/orders`; a business-linked user (owner or staff)
  /// additionally gets `business-partners/{id}/orders` and
  /// `business-partners/{id}/reviews`. Call once per app-session, right
  /// after login / app-restore — see [MercureController].
  Future<MercureCredentials> fetchMercureToken() async {
    AppLogger.info(_tag, 'GET ${ApiEndpoints.mercureToken}');
    final response = await _api.dio.get(ApiEndpoints.mercureToken);
    return MercureCredentials.fromJson(response.data as Map<String, dynamic>);
  }

  /// Updates editable profile fields (firstName, lastName, phone) for the given
  /// user [uuid]. Uses the /users/{uuid}/profile endpoint which syncs both the
  /// local DB and Keycloak atomically — email is never sent here.
  ///
  /// Throws [DioException] on failure. A 503 means the sync failed safely
  /// (both stores reverted) and the caller should show a retry prompt.
  Future<UserModel> updateMyProfile(
    String uuid,
    Map<String, dynamic> fields,
  ) async {
    AppLogger.info(
      _tag,
      'PATCH ${ApiEndpoints.userProfile(uuid)} fields=${fields.keys.toList()}',
    );
    try {
      final response = await _api.dio.patch(
        ApiEndpoints.userProfile(uuid),
        data: fields,
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Profile $uuid updated successfully');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'updateMyProfile($uuid) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
