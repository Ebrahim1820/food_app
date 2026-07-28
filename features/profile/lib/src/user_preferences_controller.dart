import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'user_preferences_model.dart';
import 'package:get/get.dart';

/// Loads and persists the per-account notification preferences for the signed-in
/// customer: email notifications and marketing/promotional opt-in.
///
/// onInit fetches from GET /users/me/preferences.
/// setEmail / setMarketing PATCH immediately — no Save button needed.
class UserPreferencesController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;

  static const _tag = 'UserPreferencesController';

  final isLoading = false.obs;

  /// Whether the account receives email notifications (e.g. order confirmations).
  final emailEnabled = true.obs;

  /// Marketing / promotional opt-in. Defaults false (GDPR — explicit consent required).
  final marketingEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetch();
  }

  Future<void> _fetch() async {
    isLoading.value = true;
    try {
      final res = await _dio.get(ApiEndpoints.userPreferences);
      final model = UserPreferencesModel.fromJson(
        res.data as Map<String, dynamic>,
      );
      emailEnabled.value = model.emailNotificationsEnabled;
      marketingEnabled.value = model.marketingEnabled;
      AppLogger.info(_tag, 'Preferences loaded');
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to load preferences',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Optimistically updates the observable and PATCHes the backend.
  /// Reverts on failure so the UI reflects the true server state.
  Future<void> setEmail(bool v) async {
    final prev = emailEnabled.value;
    emailEnabled.value = v;
    try {
      await _dio.patch(
        ApiEndpoints.userPreferences,
        data: {'emailNotificationsEnabled': v},
      );
      AppLogger.info(_tag, 'emailEnabled → $v');
    } catch (e, st) {
      emailEnabled.value = prev;
      AppLogger.error(
        _tag,
        'Failed to set emailEnabled',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Optimistically updates the observable and PATCHes the backend.
  /// Reverts on failure so the UI reflects the true server state.
  Future<void> setMarketing(bool v) async {
    final prev = marketingEnabled.value;
    marketingEnabled.value = v;
    try {
      await _dio.patch(
        ApiEndpoints.userPreferences,
        data: {'marketingEnabled': v},
      );
      AppLogger.info(_tag, 'marketingEnabled → $v');
    } catch (e, st) {
      marketingEnabled.value = prev;
      AppLogger.error(
        _tag,
        'Failed to set marketingEnabled',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
