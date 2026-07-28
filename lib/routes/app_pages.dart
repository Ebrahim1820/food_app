import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/screens/admin/admin_dashboard_screen.dart';
import 'package:food_app/screens/auth/auth_gate.dart';
import 'package:food_app/screens/auth/login_screen.dart';
import 'package:food_app/screens/auth/email_verification_notice_screen.dart';
import 'package:food_app/screens/auth/register_screen.dart';
import 'package:food_app/screens/dashboard/view/app_shell_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_dashboard_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_settings_screen.dart';
import 'package:food_app/screens/shared/settings_screen.dart';
import 'package:food_app/screens/food_teil/business_views/team_members_screen.dart';
import 'package:food_app/screens/cosmetic_teil/business_views/my_products_screen.dart';
import 'package:food_app/screens/shared/notifications_screen.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';

class AppPages {
  static final routes = [
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

    // The one persistent post-login shell for everyone except admins —
    // market tiles, Food browse, and Cosmetics browse are all just
    // different states of AppShellScreen's Home tab (see its doc comment).
    // Both names resolve to the same widget; see AppRoutes' doc comment.
    GetPage(name: AppRoutes.dashboard, page: () => const AppShellScreen()),
    GetPage(name: AppRoutes.mainNavigation, page: () => const AppShellScreen()),

    // Business partner experience.
    // BusinessPartnerController.fetchMyPartner() is called by LoginController
    // and AuthGate BEFORE this page is built, so partnerName is always ready.
    GetPage(
      name: AppRoutes.businessDashboard,
      page: () => BusinessDashboardScreen(
        businessName: Get.find<BusinessPartnerController>().partnerName,
      ),
    ),

    // Cosmetic (and any other non-Food market) business partner's minimal
    // "My Products" screen — see MyProductsScreen's doc comment for why this
    // isn't a full BusinessDashboardScreen-style shell.
    GetPage(
      name: AppRoutes.cosmeticBusinessProducts,
      page: () => const MyProductsScreen(),
    ),

    // Shared settings screen (language toggle, etc.)
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),

    // Shared notification history — used by both customer and business bells.
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
    ),

    // Business settings sub-pages.
    GetPage(name: AppRoutes.teamMembers, page: () => const TeamMembersScreen()),

    GetPage(
      name: AppRoutes.businessSettings,
      page: () => const BusinessSettingsScreen(),
    ),

    // Admin experience.
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardScreen(),
    ),
  ];
}
