import 'package:flutter/material.dart';
import 'package:food_app/constants/api_constants.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/controllers/mercure_controller.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';

/// Entry point: shows an animated splash while it decides where to send the
/// user, then redirects with GetX. See [_resolveTargetRoute] for the full
/// per-role breakdown.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
    _bootstrap();
  }

  /// Runs route resolution and the minimum splash delay in parallel.
  /// Navigation only happens after BOTH complete so the splash always
  /// shows for at least 1.6 s even when the auth check is instant.
  Future<void> _bootstrap() async {
    String? targetRoute;
    await Future.wait([
      ApiConstants.resolveDevHost(),
      _resolveTargetRoute().then((r) => targetRoute = r),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);
    // Clears the stack so the back button can't return to the splash.
    Get.offAllNamed(targetRoute!);
  }

  /// Determines the correct first screen based on the stored token:
  ///   • No valid token   → login
  ///   • ROLE_ADMIN       → admin dashboard
  ///   • Everything else  → the Dashboard (market tiles) — business
  ///     partners/staff land here too now, not a specific market's business
  ///     screen (see KeycloakAuthService.homeRouteForRoles's doc comment for
  ///     why: a business can operate in more than one market, so there's no
  ///     longer a single "the" business screen to jump to automatically).
  Future<String> _resolveTargetRoute() async {
    final auth = Get.find<AuthController>();

    if (!auth.isLoggedIn) return AppRoutes.login;

    // Same spot as the fetchMyPartner() call below — restore the Mercure
    // subscriber credential for a returning session. Fire-and-forget so a
    // network hiccup here never blocks or fails app startup.
    Get.find<MercureController>().ensureLoaded();

    if (auth.isAdmin) return AppRoutes.adminDashboard;

    if (auth.hasBusinessDashboardAccess) {
      // Warm up business partner data (name/markets/id) so the Dashboard
      // tiles and drawer are ready immediately once the user taps into
      // their business — doesn't affect where we land right now, so a
      // failure here is non-fatal; the relevant screen will show its own
      // error/retry state when the user actually navigates there.
      try {
        await Get.find<BusinessPartnerController>().fetchMyPartner();
      } catch (_) {}
    }

    return AppRoutes.dashboard;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark1, AppColors.primaryDark2],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: _blob(180, AppColors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: _blob(140, AppColors.white.withValues(alpha: 0.10)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icon/perka_mark_dark.png',
                            width: 68,
                            height: 68,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          Text(
                            'splash_appName'.tr,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'splash_tagline'.tr,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 56),
                child: FadeTransition(
                  opacity: _fade,
                  child: const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
