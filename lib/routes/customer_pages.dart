import 'package:food_app/screens/dashboard/view/app_shell_screen.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';

/// Customer Experience team's routes. Owned by that team — PRs adding a
/// customer-facing route touch only this file, not a shared route table.
abstract class CustomerPages {
  static final pages = [
    // The one persistent post-login shell for everyone except admins —
    // market tiles, Food browse, and Cosmetics browse are all just
    // different states of AppShellScreen's Home tab (see its doc comment).
    // Both names resolve to the same widget; see AppRoutes' doc comment.
    GetPage(name: AppRoutes.dashboard, page: () => const AppShellScreen()),
    GetPage(name: AppRoutes.mainNavigation, page: () => const AppShellScreen()),
  ];
}
