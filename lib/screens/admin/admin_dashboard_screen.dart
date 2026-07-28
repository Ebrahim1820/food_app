import 'package:flutter/material.dart';
import 'package:food_app/bindings/initial_binding.dart';
import 'package:food_app/controllers/admin_controller.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:food_app/screens/admin/tabs/admin_customers_tab.dart';
import 'package:food_app/screens/admin/tabs/admin_offers_tab.dart';
import 'package:food_app/screens/admin/tabs/admin_overview_tab.dart';
import 'package:food_app/screens/admin/tabs/admin_partners_tab.dart';
import 'package:food_app/screens/dashboard/view/dashboard_shell.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

// Dashboard background — light cool-gray used widely in SaaS dashboards
const _kBg = Color(0xFFF0F4F8);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminController _ctrl = Get.find<AdminController>();
  final AuthController _auth = Get.find<AuthController>();

  int _navIndex = 0;

  static const _tabs = [
    (Icons.grid_view_rounded, 'Overview'),
    (Icons.storefront_rounded, 'Partners'),
    (Icons.people_alt_rounded, 'Customers'),
    (Icons.lunch_dining_rounded, 'Offers'),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      marketKey: 'admin',
      backgroundColor: _kBg,
      appBarBackgroundColor: AppColors.navy,
      appBarForegroundColor: AppColors.white,
      // Original AppBar was flat, no shadow.
      appBarElevation: 0,
      // Admin isn't a market shell — no drawer, no language/notification
      // icons (it never had them), just its own icon+title+avatar/refresh/logout.
      showLanguageSwitcher: false,
      showNotificationBell: false,
      safeAreaTop: false,
      safeAreaBottom: false,
      title: 'Admin Panel',
      extraActions: [
        Obx(() {
          final name = _auth.firstName;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.9),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh',
          onPressed: _ctrl.fetchAll,
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
        const SizedBox(width: 4),
      ],
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      children: [
        // One isFromCache flag covers all five AdminController fetches
        // (stats/partners/customers/offers/orders) at once, so a single
        // banner above every tab is enough — no per-tab duplication needed.
        Obx(
          () => _ctrl.isFromCache.value
              ? StaleBanner(onRefresh: _ctrl.fetchAll)
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: IndexedStack(
            index: _navIndex,
            children: [
              AdminOverviewTab(
                ctrl: _ctrl,
                onGoToPartners: () => setState(() => _navIndex = 1),
                onGoToCustomers: () => setState(() => _navIndex = 2),
              ),
              AdminPartnersTab(ctrl: _ctrl),
              AdminCustomersTab(ctrl: _ctrl),
              AdminOffersTab(ctrl: _ctrl),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _navIndex,
      onDestinationSelected: (i) => setState(() => _navIndex = i),
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.navy.withValues(alpha: 0.08),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 64,
      destinations: _tabs
          .map(
            (t) => NavigationDestination(
              icon: Icon(t.$1, color: AppColors.gray400),
              selectedIcon: Icon(t.$1, color: AppColors.navy),
              label: t.$2,
            ),
          )
          .toList(),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await Get.find<KeycloakAuthService>().logout();
    await _auth.logout();
    Get.offAllNamed(AppRoutes.login);
    InitialBinding.clearUserControllers();
  }
}
