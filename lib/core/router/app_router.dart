import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
// import other screens:
import '../../features/auth/presentation/listings_screen.dart';
import '../../features/auth/presentation/bp_dashboard_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: SplashScreen.routePath,
  routes: [
    GoRoute(
      path: SplashScreen.routePath,
      builder: (c, s) => const SplashScreen(),
    ),
    GoRoute(
      path: LoginScreen.routePath,
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(
      path: RegisterScreen.routePath,
      builder: (c, s) => const RegisterScreen(),
    ),
    GoRoute(
      path: ListingsScreen.routePath,
      builder: (c, s) => const ListingsScreen(),
    ),
    GoRoute(
      path: BpDashboardScreen.routePath, 
      builder: (c, s) => const BpDashboardScreen(),
    ),
  ],
);