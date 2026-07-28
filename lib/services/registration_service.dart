import 'package:dio/dio.dart';
import 'package:core/core.dart';

typedef RegisterResult = ({
  bool success,
  Map<String, String> fieldErrors,
  String? error,
});

/// Handles the public `/register` endpoint that creates new user accounts.
///
/// Registration happens BEFORE the user has a token, so this service uses its
/// own bare Dio instance without an Authorization header.
class RegistrationService {
  static const _tag = 'RegistrationService';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String accountType,
    String? businessName,
    String? market,
    required Map<String, String> address,
  }) async {
    AppLogger.info(
      _tag,
      'POST /register email=$email accountType=$accountType market=$market',
    );
    try {
      final payload = {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'accountType': accountType,
        if (businessName != null && businessName.isNotEmpty)
          'businessName': businessName,
        if (market != null && market.isNotEmpty) 'market': market,
        'address': address,
      };
      AppLogger.info(_tag, 'POST /register payload: $payload');
      await _dio.post('/register', data: payload);
      AppLogger.info(_tag, 'Registration successful for $email');
      return (success: true, fieldErrors: <String, String>{}, error: null);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      AppLogger.error(
        _tag,
        'Registration failed (HTTP $status)',
        error: data,
        stackTrace: null,
      );

      if (status == 422 && data is Map && data['errors'] is Map) {
        final raw = Map<String, dynamic>.from(data['errors'] as Map);
        final fieldErrors = raw.map((k, v) => MapEntry(k, v.toString()));
        return (success: false, fieldErrors: fieldErrors, error: null);
      }

      if (status == 409) {
        return (
          success: false,
          fieldErrors: <String, String>{
            'email': 'An account with this email already exists.',
          },
          error: null,
        );
      }

      if (status != null && status >= 500) {
        return (
          success: false,
          fieldErrors: <String, String>{},
          error:
              'Registration is temporarily unavailable. Please try again later.',
        );
      }

      final msg = (data is Map)
          ? (data['error'] ?? data['message'])?.toString()
          : null;
      return (
        success: false,
        fieldErrors: <String, String>{},
        error: msg ?? 'Could not create account. Please try again.',
      );
    }
  }
}
