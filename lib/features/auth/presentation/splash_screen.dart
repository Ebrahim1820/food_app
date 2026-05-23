import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_provider.dart';

/// Shown briefly on app start.
/// Checks if there's an existing session and redirects accordingly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/splash';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // ...existing code...
  Future<void> _checkAuth() async {
    // Small delay for branding moment
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    try {
      // give checkSession a short timeout so a stuck call won't block navigation
      await ref
          .read(authProvider.notifier)
          .checkSession()
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      debugPrint('auth checkSession error/timeout: $e\n$st');
      // proceed to navigation fallback below
    }

    if (!mounted) return;

    final state = ref.read(authProvider);
    debugPrint('Splash: auth state after check -> $state');

    if (state is AuthAuthenticated) {
      final user = state.user;
        context.go(user.isBusinessPartner ? '/bp/dashboard' : '/listings');
    } else {
      context.go('/login');
    }
  }
// ...existing code...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'FoodRescue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Less waste. More taste...!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
