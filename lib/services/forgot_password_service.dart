import 'package:dio/dio.dart';
import 'package:food_app/constants/api_endpoints.dart';
import 'package:food_app/network/api_service.dart';
import 'package:food_app/utils/app_logger.dart';

class ForgotPasswordService {
  const ForgotPasswordService(this._api);

  final ApiService _api;
  static const _tag = 'ForgotPasswordService';

  /// Always returns normally — the API responds 200 whether the email exists
  /// or not, to prevent email enumeration. Only throws on network failure.
  Future<void> forgotPassword(String email) async {
    AppLogger.info(_tag, 'POST forgot-password');
    try {
      await _api.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
        options: Options(extra: {'noAuth': true}),
      );
      AppLogger.info(_tag, 'Reset request sent');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'forgotPassword failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
