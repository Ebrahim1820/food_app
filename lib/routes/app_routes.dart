abstract class AppRoutes {
  static const splash = '/splash'; // auth gate (app entry point)
  // Both resolve to the same AppShellScreen (the one persistent post-login
  // shell) — `dashboard` is the canonical post-login redirect name,
  // `mainNavigation` is the "already on the shell" alias several call sites
  // outside the shell itself still use.
  static const dashboard = '/dashboard';
  static const mainNavigation = '/';
  static const businessDashboard = '/business'; // business partner experience
  // Cosmetic (and any other non-Food market) business partner's minimal
  // "My Products" screen — deliberately not a full dashboard shell like
  // [businessDashboard], see MyProductsScreen's doc comment.
  static const cosmeticBusinessProducts = '/business/cosmetic/products';
  static const adminDashboard = '/admin'; // admin experience
  static const users = '/users';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmailNotice = '/verify-email-notice';
  static const teamMembers = '/business/team-members';
  static const businessSettings = '/business/business-settings';
  static const settings = '/settings';
  static const notifications = '/notifications';

  /// Picks which business-side "home" screen a business partner/staff
  /// account lands on right after login, based on which market(s) their
  /// business operates in (`BusinessPartnerModel.markets`).
  ///
  /// Food gets the full [businessDashboard] (earnings/analytics/team
  /// management); a business with ONLY Cosmetic (no Food) gets the generic
  /// Product pipeline's [cosmeticBusinessProducts] instead — there's no
  /// unified multi-market dashboard yet, so Food wins when a business has
  /// both. Defaults to [businessDashboard] for empty/unrecognized markets,
  /// matching every account created before market tracking existed.
  static String businessHomeForMarkets(List<String> markets) {
    if (markets.contains('food')) return businessDashboard;
    if (markets.contains('cosmetic')) return cosmeticBusinessProducts;
    return businessDashboard;
  }
}
