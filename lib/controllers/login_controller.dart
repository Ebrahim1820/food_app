import 'package:auth/auth.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:notification/notification.dart';
import 'package:core/core.dart';
import 'package:food_app/services/push_notification_service.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Logic only. The TextEditingControllers and the form key now live in the
/// LoginScreen's State (so Flutter manages their lifecycle), which avoids the
/// "duplicate GlobalKey" and "used after disposed" errors entirely.
class LoginController extends GetxController {
  final isLoading = false.obs;

  final KeycloakAuthService _auth = Get.find<KeycloakAuthService>();
  final AuthController _authController = Get.find<AuthController>();

  /// Receives the field values from the screen.
  Future<void> signIn(String username, String password) async {
    isLoading.value = true;
    try {
      final token = await _auth.login(username, password);

      await _authController.setToken(token);

      // Register device for push — fire-and-forget so a push setup failure
      // never blocks the login flow or shows a confusing error to the user.
      Get.find<PushNotificationService>().init().catchError((e, st) {
        AppLogger.warning(
          'LoginController',
          'Push init failed (non-fatal): $e',
        );
      });

      // Same spot as the /users/me calls below — fetch the Mercure
      // subscriber credential once per session. Fire-and-forget: a failure
      // here shouldn't block login, it just means live updates stay off
      // until the next proactive refresh.
      Get.find<MercureController>().ensureLoaded().catchError((e, st) {
        AppLogger.warning(
          'LoginController',
          'Mercure token fetch failed (non-fatal): $e',
        );
      });

      final roles = _auth.getRolesFromToken(token);

      if (roles.contains('ROLE_BUSINESS_PARTNER') ||
          roles.contains('ROLE_MEMBER')) {
        // fetchMyPartner calls /users/me internally and sets isEmailVerified.
        await Get.find<BusinessPartnerController>().fetchMyPartner();
      } else {
        // For customers there's no eager partner fetch, so kick off a
        // fire-and-forget check so isEmailVerified is ready before checkout.
        _authController.refreshVerificationStatus();
      }

      Get.offAllNamed(_auth.homeRouteForRoles(roles));
    } on Exception catch (e) {
      final msg = e.toString();
      final isCredentials = msg.contains('incorrect_credentials');
      final isUnreachable = msg.contains('server_unreachable');
      AppSnackbar.error(
        isCredentials
            ? 'login_failedTitle'.tr
            : 'login_connectionErrorTitle'.tr,
        isCredentials
            ? 'login_incorrectCredentials'.tr
            : isUnreachable
            ? 'login_serverUnreachable'.tr
            : 'login_unexpectedError'.trParams({'error': '$e'}),
      );
      AppLogger.error('LoginController', 'Sign-in failed', error: e);
    } finally {
      isLoading.value = false;
    }
  }
}
