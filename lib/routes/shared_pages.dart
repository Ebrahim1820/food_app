import 'package:food_app/screens/auth/auth_gate.dart';
import 'package:food_app/screens/auth/login_screen.dart';
import 'package:food_app/screens/auth/email_verification_notice_screen.dart';
import 'package:food_app/screens/auth/register_screen.dart';
import 'package:food_app/screens/shared/settings_screen.dart';
import 'package:food_app/screens/shared/notifications_screen.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';

/// Routes that exist before a role is known (auth) or are used by more than
/// one team's screens (settings, the shared notification bell history).
/// Owned jointly — changes here are rare, so this staying shared doesn't
/// reproduce the single-file bottleneck the split routes files exist to fix.
abstract class SharedPages {
  static final pages = [
    // Entry point: checks tokens, then redirects by role.
    GetPage(name: AppRoutes.splash, page: () => const AuthGate()),

    // Auth screens. Each owns its own form state (StatefulWidget), and gets
    // its logic controller via Get.put in initState.
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(
      name: AppRoutes.verifyEmailNotice,
      page: () => const EmailVerificationNoticeScreen(),
    ),

    // Shared settings screen (language toggle, etc.)
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),

    // Shared notification history — used by both customer and business bells.
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
    ),
  ];
}
