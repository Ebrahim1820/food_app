import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Manages push-notification preferences for the business partner account.
///
/// Lifecycle:
///   onInit → GET /business-partners/me/notification-preferences
///   save() → PATCH the same endpoint (called by the Save button only)
///
/// Each preference field is an `Rx<bool>` so the screen can react reactively
/// without needing setState.
class BpNotifPrefsController extends GetxController {
  final Dio _dio = Get.find<ApiService>().dio;

  static const _tag = 'BpNotifPrefsController';

  final isLoading = false.obs;
  final isSaving = false.obs;

  // ── Orders ──────────────────────────────────────────────────────────────────
  final notifyNewOrder = true.obs;
  final notifyOrderReady = true.obs;
  final notifyOrderCancelled = true.obs;

  // ── Reviews ─────────────────────────────────────────────────────────────────
  final notifyNewReview = true.obs;
  final notifyReviewReply = false.obs;

  // ── Marketing ────────────────────────────────────────────────────────────────
  final notifyPromotions = false.obs;
  final notifyGrowthTips = true.obs;

  // ── System ───────────────────────────────────────────────────────────────────
  final notifyMaintenanceAlerts = true.obs;
  final notifyAppUpdates = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetch();
  }

  Future<void> _fetch() async {
    isLoading.value = true;
    try {
      final res = await _dio.get(ApiEndpoints.bpNotifPrefs);
      _applyModel(BpNotifPrefsModel.fromJson(res.data as Map<String, dynamic>));
      AppLogger.info(_tag, 'Notification preferences loaded');
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to load notification preferences',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyModel(BpNotifPrefsModel m) {
    notifyNewOrder.value = m.notifyNewOrder;
    notifyOrderReady.value = m.notifyOrderReady;
    notifyOrderCancelled.value = m.notifyOrderCancelled;
    notifyNewReview.value = m.notifyNewReview;
    notifyReviewReply.value = m.notifyReviewReply;
    notifyPromotions.value = m.notifyPromotions;
    notifyGrowthTips.value = m.notifyGrowthTips;
    notifyMaintenanceAlerts.value = m.notifyMaintenanceAlerts;
    notifyAppUpdates.value = m.notifyAppUpdates;
  }

  /// Sends all current toggle values to the backend via PATCH.
  /// Called only when the user taps the Save button.
  Future<void> save() async {
    isSaving.value = true;
    try {
      final body = BpNotifPrefsModel(
        notifyNewOrder: notifyNewOrder.value,
        notifyOrderReady: notifyOrderReady.value,
        notifyOrderCancelled: notifyOrderCancelled.value,
        notifyNewReview: notifyNewReview.value,
        notifyReviewReply: notifyReviewReply.value,
        notifyPromotions: notifyPromotions.value,
        notifyGrowthTips: notifyGrowthTips.value,
        notifyMaintenanceAlerts: notifyMaintenanceAlerts.value,
        notifyAppUpdates: notifyAppUpdates.value,
      ).toJson();
      AppLogger.info(_tag, 'PATCH ${ApiEndpoints.bpNotifPrefs} body=$body');
      final res = await _dio.patch(ApiEndpoints.bpNotifPrefs, data: body);
      AppLogger.info(
        _tag,
        'PATCH response → ${res.statusCode} body=${res.data}',
      );
      AppLogger.info(_tag, 'Notification preferences saved');
      AppSnackbar.success(
        BusinessNotifStrings.savedSnack,
        BusinessNotifStrings.savedSnackBody,
      );
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to save notification preferences',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.error(ErrorStrings.title, ErrorStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
