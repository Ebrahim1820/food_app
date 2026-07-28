import 'package:flutter/material.dart';
import 'package:food_app/bindings/initial_binding.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/screens/auth/keycloak_auth_service.dart';
import 'package:food_app/screens/auth/login_screen.dart';
import 'package:food_app/services/cache_service.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:get/get.dart';

/// A reusable logout control.
///
/// Ends the Keycloak session, clears the stored token, and returns to the
/// login screen. Renders in one of two styles depending on [isFullColorButton].
///
/// ```dart
/// const LogoutWidget();                        // compact list tile
/// const LogoutWidget(isFullColorButton: true); // full-width red button
/// ```
class LogoutWidget extends StatelessWidget {
  /// How the control looks.
  ///
  /// * `false` (default) → a red [ListTile], for drawers and menus.
  /// * `true` → a full-width red [ElevatedButton], for profile/settings pages.
  final bool isFullColorButton;

  /// Creates a logout control.
  ///
  /// Set [isFullColorButton] to `true` for the large button style.
  const LogoutWidget({super.key, this.isFullColorButton = false});

  Future<void> _logout() async {
    final auth = Get.find<KeycloakAuthService>();
    await auth.logout();
    await Get.find<AuthController>().logout();
    // Navigate away before tearing down user-scoped controllers below —
    // clearUserControllers() force-disposes things like
    // DashboardController.searchController synchronously, and AppShellScreen
    // stays mounted and rebuilding for the duration of the outgoing route's
    // transition *animation*, not just until this call returns. A normal
    // offAllNamed keeps AppShellScreen alive across several more animated
    // frames, so the synchronous delete right below still raced it and threw
    // "TextEditingController used after being disposed". noTransition/zero
    // duration removes the animated frames entirely, so the shell is gone
    // before the next line runs.
    Get.offAll(
      () => const LoginScreen(),
      routeName: AppRoutes.login,
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
    // Destroy all user-scoped controllers so the next login gets fresh data
    // (prevents stale orders/offers from Partner A leaking into Partner B).
    InitialBinding.clearUserControllers();
    // FIX: clearUserControllers() only resets in-memory GetX state — it did
    // NOT clear the on-disk DataCacheService cache (business_partner,
    // business_offers_*, dashboard_data, ...), which is keyed by resource
    // name only, not per-user. Without this, BusinessPartnerController's
    // next fetchMyPartner() would show Partner A's cached business identity
    // (name, markets, ...) immediately on Partner B's login — before the
    // fresh /users/me response corrected it — which could route Partner B's
    // "switch to business view" straight to Partner A's dashboard for the
    // instant that stale read wins. See CacheService.clearAll() — same
    // clear used by Settings' manual "Clear cache" action.
    await CacheService.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return isFullColorButton
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _logout,
                child: Text(CustomerProfileStrings.logoutButton),
              ),
            ),
          )
        : ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              CustomerProfileStrings.logoutButton,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: _logout,
          );
  }
}
