import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/screens/auth/keycloak_auth_service.dart';
import 'package:food_app/services/user_service.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

class CustomerEditProfileController extends GetxController {
  CustomerEditProfileController(this._userService);

  final UserService _userService;

  final _auth = Get.find<AuthController>();
  final _keycloak = Get.find<KeycloakAuthService>();

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  final isLoading = true.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Pre-fill first name immediately from the JWT so the field isn't blank
    // during the /users/me fetch.
    firstNameCtrl.text = _auth.firstName == 'there' ? '' : _auth.firstName;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userService.fetchMe();
      firstNameCtrl.text = user.firstName;
      lastNameCtrl.text = user.lastName;
      phoneCtrl.text = user.phone ?? '';
    } catch (_) {
      // JWT first name is already set; last name / phone remain blank.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    final fields = <String, dynamic>{
      'firstName': firstNameCtrl.text.trim(),
      'lastName': lastNameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
    };

    isSaving.value = true;
    try {
      await _userService.updateMyProfile(_auth.userId, fields);

      // Force-refresh the JWT so AuthController getters (firstName, fullName)
      // reflect the new values without requiring a re-login.
      final newToken = await _keycloak.forceRefreshToken();
      if (newToken != null) await _auth.setToken(newToken);

      Get.back();
      AppSnackbar.success(
        CustomerProfileStrings.editProfileTitle,
        CustomerProfileStrings.profileUpdated,
      );
    } on DioException catch (e) {
      final is503 = e.response?.statusCode == 503;
      AppSnackbar.error(
        CustomerProfileStrings.editProfileTitle,
        is503
            ? CustomerProfileStrings.saveRetry
            : CustomerProfileStrings.saveError,
      );
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
