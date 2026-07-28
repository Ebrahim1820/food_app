import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/models/food_models/business_models/bp_email_prefs_model.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Manages email-alert preferences for the business partner account.
///
/// Lifecycle:
///   onInit → GET /business-partners/me/email-preferences
///   save() → PATCH the same endpoint (called by the Save button only)
class BpEmailPrefsController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;

  static const _tag = 'BpEmailPrefsController';

  final isLoading = false.obs;
  final isSaving = false.obs;

  // ── Reports ──────────────────────────────────────────────────────────────────
  final emailDailySummary = true.obs;
  final emailWeeklyReport = true.obs;
  final emailMonthlyReport = false.obs;

  // ── Orders ───────────────────────────────────────────────────────────────────
  final emailOrderConfirmation = false.obs;
  final emailRefundAlert = true.obs;

  // ── Reviews ──────────────────────────────────────────────────────────────────
  final emailNewReview = true.obs;
  final emailLowRatingAlert = true.obs;

  @override
  void onInit() {
    super.onInit();
    _fetch();
  }

  Future<void> _fetch() async {
    isLoading.value = true;
    try {
      final res = await _dio.get(ApiEndpoints.bpEmailPrefs);
      _applyModel(BpEmailPrefsModel.fromJson(res.data as Map<String, dynamic>));
      AppLogger.info(_tag, 'Email preferences loaded');
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to load email preferences',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyModel(BpEmailPrefsModel m) {
    emailDailySummary.value = m.emailDailySummary;
    emailWeeklyReport.value = m.emailWeeklyReport;
    emailMonthlyReport.value = m.emailMonthlyReport;
    emailOrderConfirmation.value = m.emailOrderConfirmation;
    emailRefundAlert.value = m.emailRefundAlert;
    emailNewReview.value = m.emailNewReview;
    emailLowRatingAlert.value = m.emailLowRatingAlert;
  }

  /// Sends all current toggle values to the backend via PATCH.
  /// Called only when the user taps the Save button.
  Future<void> save() async {
    isSaving.value = true;
    try {
      await _dio.patch(
        ApiEndpoints.bpEmailPrefs,
        data: BpEmailPrefsModel(
          emailDailySummary: emailDailySummary.value,
          emailWeeklyReport: emailWeeklyReport.value,
          emailMonthlyReport: emailMonthlyReport.value,
          emailOrderConfirmation: emailOrderConfirmation.value,
          emailRefundAlert: emailRefundAlert.value,
          emailNewReview: emailNewReview.value,
          emailLowRatingAlert: emailLowRatingAlert.value,
        ).toJson(),
      );
      AppLogger.info(_tag, 'Email preferences saved');
      AppSnackbar.success(
        BusinessEmailStrings.savedSnack,
        BusinessEmailStrings.savedSnackBody,
      );
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to save email preferences',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.error(ErrorStrings.title, ErrorStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
