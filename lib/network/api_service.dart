import 'package:dio/dio.dart';
import 'package:food_app/screens/auth/auth_interceptor.dart';
import 'package:food_app/screens/auth/keycloak_auth_service.dart';
import '../constants/api_constants.dart';

/// The single HTTP client for the whole app. Every service (FoodOfferService,
/// OrderService, etc.) talks to the backend through this one `dio` instance,
/// so configuring auth here means EVERY request is authenticated automatically.
class ApiService {
  /// We receive the auth service from outside (dependency injection) rather
  /// than creating it here, so the same KeycloakAuthService instance is shared
  /// with the login screen, logout button, etc.
  ApiService(this._auth) {
    // Rewrite baseUrl on every request so it always uses the host that
    // resolveDevHost() settled on — the Dio instance may be constructed
    // before the host probe completes, so we can't bake it into BaseOptions.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = ApiConstants.baseUrl;
          handler.next(options);
        },
      ),
    );
    dio.interceptors.add(AuthInterceptor(_auth, dio));
  }

  /// The shared auth service: knows how to get/refresh the access token.
  final KeycloakAuthService _auth;

  /// The configured Dio client. baseUrl is set dynamically per-request by the
  /// interceptor above, so it always reflects the resolved dev host.
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/ld+json'},
    ),
  );
}
