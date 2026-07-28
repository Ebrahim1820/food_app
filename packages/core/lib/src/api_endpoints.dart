// lib/core/constants/api_endpoints.dart
abstract class ApiEndpoints {
  //   static const login = '/login';
  //   static const register = '/register';

  static const users = '/users';

  /// Full JSON-LD IRI for a user, e.g. for avatar-upload requests that
  /// reference "who this image belongs to" rather than fetching the user.
  static String userIri(String id) => '/api/users/$id';

  static const businessPartners = '/business-partners';

  static String businessPartnerIri(String id) => '/api/business-partners/$id';

  static String businessPartnerClose(int id) => '/business-partners/$id/close';

  /// GET /me/mercure-token — replaces the old per-business
  /// `/business-partners/me/mercure-token` (single `topic`). This one is
  /// called once per session for every logged-in user and returns a
  /// `topics` array scoped to their role(s).
  static const mercureToken = '/me/mercure-token';

  /// Generic, market-agnostic listing resource — every market, Food included,
  /// reads/writes here (filter by `market` query param / body key). Replaces
  /// the old per-market `/food-offers` and `/cosmetic-offers/sections`.
  static const products = '/products';

  static const productSections = '/products/sections';

  /// GET /dashboard — public, powers the post-login Dashboard screen (market
  /// tiles + coming-soon list) and the registration screen's business-market
  /// dropdown (called before the user has an account).
  static const dashboard = '/dashboard';

  static const favorites = '/favorites';

  static const uploadImage = '/images';

  static const addresses = '/addresses';

  static const orders = '/orders';

  static String orderIri(String id) => '/api/orders/$id';

  static const orderItems = '/order-items';

  static const reviews = '/reviews';

  static String review(String id) => '/reviews/$id';

  static const bankAccounts = '/business-bank-accounts';

  static const customerBankAccounts = '/customer-bank-accounts';

  static const changePassword = '/change-password';

  static const forgotPassword = '/forgot-password';

  static String userProfile(String uuid) => '/users/$uuid/profile';

  static const deviceTokens = '/device-tokens';

  static String deviceToken(String id) => '/device-tokens/$id';

  static const userPreferences = '/users/me/preferences';

  static const bpNotifPrefs = '/business-partners/me/notification-preferences';

  static const bpEmailPrefs = '/business-partners/me/email-preferences';

  static const notifications = '/notifications';

  static const notificationsUnreadCount = '/notifications/unread-count';

  static String notificationRead(String id) => '/notifications/$id';

  static const notificationsReadAll = '/notifications/read-all';

  /// POST /admin/notifications/broadcast — admin only, fire-once-now push +
  /// notification-history row to every customer. `{title, body}` in,
  /// `{success, recipientCount}` out.
  static const adminNotificationsBroadcast = '/admin/notifications/broadcast';
}
