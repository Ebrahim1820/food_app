import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:food_app/screens/food_teil/business_views/business_dashboard_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_notifications_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_security_screen.dart';
import 'package:food_app/screens/shared/settings_screen.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:food_app/widgets/logout_widget.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';

/// Seller Platform team's routes. Owned by that team — PRs adding a
/// business-facing route touch only this file, not a shared route table.
abstract class SellerPages {
  static final pages = [
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
      page: () => MyProductsScreen(
        onSwitchToCustomerView: () {
          final nav = Get.find<NavigationController>();
          nav.actingAsCustomer.value = true;
          nav.activeMarket.value = null;
          nav.currentIndex.value = 0;
          Get.offNamed(AppRoutes.dashboard);
        },
        onOpenSettings: () => Get.to(() => const SettingsScreen()),
        drawerFooter: const LogoutWidget(),
      ),
    ),

    // Business settings sub-pages.
    GetPage(name: AppRoutes.teamMembers, page: () => const TeamMembersScreen()),

    GetPage(
      name: AppRoutes.businessSettings,
      page: () => BusinessSettingsScreen(
        onOpenNotifications: () =>
            Get.to(() => const BusinessNotificationsScreen()),
        onOpenSecurity: () => Get.to(() => const BusinessSecurityScreen()),
      ),
    ),
  ];
}
