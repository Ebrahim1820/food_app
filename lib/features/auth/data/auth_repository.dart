import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../core/api/api_client.dart';
// import '../../../core/api/api_endpoints.dart';
import '../data/auth_local_storage.dart';
import '../models/user_model.dart';


// Define the missing apiClientProvider
final apiClientProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );
});
/// All authentication API calls live here.
/// Screens never call Dio directly — always go through this repository.
///
/// MOCK MODE: set [_useMock] to true while the Symfony backend isn't ready.
/// Flip to false and uncomment the real calls when your API is running.
class AuthRepository {
  const AuthRepository(this._dio, this._storage);

  // ─── toggle this when your Symfony API is ready ───────────────────────────
  static const bool _useMock = true;
  // ──────────────────────────────────────────────────────────────────────────

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Login with email + password.
  /// Returns the authenticated [UserModel] and saves the token.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 900));
      // Simulate role based on email for easy testing during development
      final role = email.contains('business') ? 'business' : 'customer';
      const mockToken = 'mock_jwt_token_dev_123';
      await _storage.saveToken(mockToken);
      final user = UserModel(
        id: 'mock-user-001',
        name: role == 'business' ? 'Fresh Market GmbH' : 'Anna Müller',
        email: email,
        role: role,
        isVerified: true,
      );
      await _storage.saveUserMeta(userId: user.id, role: user.role);
      return user;
    }

    // ── Real Symfony API call (uncomment when backend is ready) ─────────────
    // try {
    //   final response = await _dio.post(
    //     ApiEndpoints.login,
    //     data: {'email': email, 'password': password},
    //   );
    //   final token = response.data['token'] as String;
    //   final user = UserModel.fromJson(
    //     response.data['user'] as Map<String, dynamic>,
    //   );
    //   await _storage.saveToken(token);
    //   await _storage.saveUserMeta(userId: user.id, role: user.role);
    //   return user;
    // } on DioException catch (e) {
    //   throw _mapDioError(e);
    // }
    throw UnimplementedError('Switch _useMock to false and uncomment real call');
  }

  /// Register a new account.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'customer' | 'business'
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 1000));
      const mockToken = 'mock_jwt_token_dev_456';
      await _storage.saveToken(mockToken);
      final user = UserModel(
        id: 'mock-user-002',
        name: name,
        email: email,
        role: role,
        isVerified: false,
      );
      await _storage.saveUserMeta(userId: user.id, role: user.role);
      return user;
    }

    // ── Real call ────────────────────────────────────────────────────────────
    // try {
    //   final response = await _dio.post(
    //     ApiEndpoints.register,
    //     data: {'name': name, 'email': email, 'password': password, 'role': role},
    //   );
    //   final token = response.data['token'] as String;
    //   final user = UserModel.fromJson(response.data['user']);
    //   await _storage.saveToken(token);
    //   await _storage.saveUserMeta(userId: user.id, role: user.role);
    //   return user;
    // } on DioException catch (e) {
    //   throw _mapDioError(e);
    // }
    throw UnimplementedError();
  }

  Future<void> logout() => _storage.clearAll();

  Future<bool> isLoggedIn() => _storage.hasToken();

  /// Maps Dio network errors to human-readable messages.
  Exception _mapDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return Exception('Invalid email or password.');
      case 422:
        final msg = e.response?.data?['message'] ?? 'Validation error.';
        return Exception(msg);
      case 429:
        return Exception('Too many attempts. Please wait a moment.');
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return Exception('Connection timed out. Check your internet.');
        }
        return Exception('Something went wrong. Please try again.');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(authLocalStorageProvider),
  ),
);
