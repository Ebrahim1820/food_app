import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/strings/error_strings.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'keycloak_auth_service.dart';

/// A Dio interceptor automatically runs on EVERY request/response that goes
/// through the Dio client it's attached to. This one does two jobs:
///   1. Attaches the Keycloak access token to outgoing requests.
///   2. Auto-refreshes the token and retries once if the server says 401.
/// So your screens just call the API — they never touch tokens directly.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._auth, this._dio);
  final KeycloakAuthService _auth;
  final Dio _dio;

  // Prevents multiple concurrent session-expired events from each firing
  // Get.offAllNamed(login), which causes duplicate navigation stack pushes.
  bool _redirecting = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Requests tagged `noAuth: true` are public endpoints that must reach the
    // server even when the user isn't logged in or doesn't exist in the app's
    // DB. Skip token injection entirely so Symfony handles them anonymously.
    if (options.extra['noAuth'] == true) {
      return handler.next(options);
    }

    final token = await _auth.getValidAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      // Distinguish a true session expiry (tokens deleted) from a transient
      // network failure during refresh (tokens still in storage).
      // Only tag as session_expired when there are genuinely no tokens left —
      // network errors should fail the request normally, not kick to login.
      final stillLoggedIn = await _auth.isLoggedIn();
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: stillLoggedIn ? 'network_unavailable' : 'session_expired',
        ),
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Session-expired rejections we created in onRequest — go to login.
    if (err.error == 'session_expired') {
      _redirectToLogin();
      return handler.next(err);
    }

    // 403 means the token is valid but the backend rejected the action on
    // role/ownership grounds (e.g. staff hitting an owner-only endpoint like
    // bank accounts or business deletion). Surface this everywhere via a
    // snackbar so screens without bespoke 403 handling don't fail silently
    // or show a generic error the user can't act on.
    //
    // Callers doing bulk/expected-to-sometimes-403 lookups (e.g. fetching N
    // team members' profiles where GET /users/{id} is self-or-admin only)
    // tag the request with `silent403` so a single failure doesn't spam N
    // stacked snackbars — that screen owns its own error message instead.
    if (err.response?.statusCode == 403 &&
        err.requestOptions.extra['silent403'] != true) {
      _showPermissionDeniedSnackbar(err.response?.data);
    }

    // Only handle the first 401; the '_retried' flag prevents loops.
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['_retried'] == true) {
      return handler.next(err);
    }

    // Force a fresh token from Keycloak — do NOT use the cached access token.
    // The cached token just got a 401, which means the server rejected it
    // (clock skew, key rotation, or revocation). getValidAccessToken() would
    // return the same cached token again if exp looks valid client-side.
    final token = await _auth.forceRefreshToken();

    if (token == null) {
      // Refresh failed → session is dead → force login.
      await _auth.logout(localOnly: true);
      _redirectToLogin();
      return handler.next(err);
    }

    // We have a valid token. Retry the original request once.
    final req = err.requestOptions
      ..headers['Authorization'] = 'Bearer $token'
      ..extra['_retried'] = true;

    try {
      return handler.resolve(await _dio.fetch(req));
    } on DioException catch (retryError) {
      // Retry failed even with a valid token.
      // This is a PERMISSIONS issue (the user lacks access to this resource),
      // NOT an expired-session issue. Do NOT force logout — let the caller
      // show an appropriate error state in the UI.
      return handler.next(retryError);
    }
  }

  void _redirectToLogin() {
    // 1. Guard against navigation if we're already on login or already redirecting
    if (_redirecting || Get.currentRoute == AppRoutes.login) return;

    _redirecting = true;

    /// 2. Schedule navigation after the current frame to prevent race conditions during hot reload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(AppRoutes.login)?.then((_) {
        // Reset flag after navigation completes so future logouts work
        _redirecting = false;
      });
    });
  }

  void _showPermissionDeniedSnackbar(dynamic responseData) {
    AppSnackbar.error(
      ErrorStrings.permissionDeniedTitle,
      _extractMessage(responseData) ?? ErrorStrings.permissionDeniedBody,
    );
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['hydra:description'] ?? data['message'])
          ?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
