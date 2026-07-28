import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/models/dashboard_model.dart';

/// Fetches the market tiles that power the post-login Dashboard screen and
/// the registration screen's business-market dropdown.
///
/// GET /dashboard is public — sent without a Bearer token (`noAuth: true`)
/// because the registration screen calls it before the user has an account.
class DashboardService {
  const DashboardService(this._api);

  final ApiService _api;
  static const _tag = 'DashboardService';

  Future<DashboardModel> fetchDashboard() async {
    AppLogger.info(_tag, 'GET ${ApiEndpoints.dashboard}');
    try {
      final response = await _api.dio.get(
        ApiEndpoints.dashboard,
        options: Options(extra: {'noAuth': true}),
      );
      final model = DashboardModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      AppLogger.info(
        _tag,
        'Fetched ${model.markets.length} market(s), '
        '${model.comingSoon.length} coming-soon',
      );
      return model;
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchDashboard failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
