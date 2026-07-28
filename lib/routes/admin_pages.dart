import 'package:food_app/screens/admin/admin_dashboard_screen.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';

/// Trust & Ops team's admin routes. Owned by that team.
abstract class AdminPages {
  static final pages = [
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardScreen(),
    ),
  ];
}
