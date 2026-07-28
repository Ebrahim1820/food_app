import 'package:dio/dio.dart';
import 'package:food_app/constants/api_endpoints.dart';
import 'package:food_app/network/api_service.dart';
import 'package:food_app/utils/app_logger.dart';

class ChangePasswordService {
  const ChangePasswordService(this._api);

  final ApiService _api;
  static const _tag = 'ChangePasswordService';

  Future<void> changePassword(String newPassword) async {
    AppLogger.info(_tag, 'POST change-password');
    try {
      await _api.dio.post(
        ApiEndpoints.changePassword,
        data: {'newPassword': newPassword},
      );
      AppLogger.info(_tag, 'Password changed successfully');
    } on DioException catch (e, st) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      AppLogger.error(
        _tag,
        'changePassword failed (HTTP $statusCode)',
        error: body,
        stackTrace: st,
      );
      if (statusCode == 422) {
        final msg =
            (body is Map ? body['error'] as String? : null) ??
            'Invalid password format.';
        throw Exception(msg);
      }
      throw Exception('Password change failed. Please try again.');
    }
  }
}
