import 'package:food_app/models/dashboard_model.dart';
import 'package:food_app/services/dashboard_service.dart';
import 'package:food_app/strings/auth_strings.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/services/registration_service.dart';

class RegisterController extends GetxController {
  final accountType = 'user'.obs;
  final isLoading = false.obs;

  /// The market selected in the business-account dropdown (e.g. "food").
  /// Null for user accounts and until the business picks one.
  final selectedMarket = RxnString();

  /// Markets open for business registration today — filtered from GET
  /// /dashboard's `businessRegistrationEnabled` flag, so a new market opening
  /// up for registration later needs zero changes here.
  final businessMarkets = <DashboardMarket>[].obs;

  /// Per-field errors returned by the backend (422) or mapped from 409.
  /// Keys match the API error map: 'email', 'password', 'fullName',
  /// 'businessName', 'market'.
  final fieldErrors = Rx<Map<String, String>>({});

  final RegistrationService _service = RegistrationService();
  final DashboardService _dashboardService = Get.find<DashboardService>();

  bool get isBusiness => accountType.value == 'business';
  void selectType(String type) => accountType.value = type;
  void selectMarket(String market) {
    selectedMarket.value = market;
    clearFieldError('market');
  }

  @override
  void onInit() {
    super.onInit();
    _loadBusinessMarkets();
  }

  /// Fire-and-forget — a failure here just leaves the dropdown empty and the
  /// user sees a "market is required" error on submit instead of a crash.
  Future<void> _loadBusinessMarkets() async {
    try {
      final dashboard = await _dashboardService.fetchDashboard();
      businessMarkets.value = dashboard.markets
          .where((m) => m.businessRegistrationEnabled)
          .toList();
    } catch (_) {
      // ignore — see doc comment above
    }
  }

  /// Clears the server error for a single field so it disappears as soon as
  /// the user starts correcting it.
  void clearFieldError(String field) {
    if (fieldErrors.value.containsKey(field)) {
      final updated = Map<String, String>.from(fieldErrors.value)
        ..remove(field);
      fieldErrors.value = updated;
    }
  }

  Future<void> submit({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? businessName,
    required Map<String, String> address,
  }) async {
    fieldErrors.value = {};
    isLoading.value = true;
    try {
      final result = await _service.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        accountType: accountType.value,
        businessName: isBusiness ? businessName : null,
        market: isBusiness ? selectedMarket.value : null,
        address: address,
      );

      if (result.success) {
        // Navigate to "check your email" notice — do NOT auto-login so the
        // user verifies before accessing the app.
        Get.toNamed(AppRoutes.verifyEmailNotice, arguments: email);
        return;
      }

      if (result.fieldErrors.isNotEmpty) {
        fieldErrors.value = result.fieldErrors;
        return;
      }

      if (result.error != null) {
        AppSnackbar.error(RegisterStrings.failed, result.error!);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
