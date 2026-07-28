import 'package:customer_experience/customer_experience.dart';
import 'package:models/models.dart';
import 'package:profile/profile.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:admin_platform/admin_platform.dart';
import 'package:auth/auth.dart';
import 'package:food_app/controllers/dashboard_controller.dart';
import 'package:location/location.dart';
import 'package:notification/notification.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:core/core.dart';
import 'package:food_app/services/dashboard_service.dart';
import 'package:design_system/design_system.dart';
import 'package:review/review.dart';
import 'package:food_app/services/change_password_service.dart';
import 'package:food_app/services/push_notification_service.dart';
import 'package:get/get.dart';
import 'package:i18n/i18n.dart';

/// GetX runs this once at app startup (wired via `initialBinding` in main.dart).
/// It builds all the shared services/controllers and registers them so any
/// screen can later fetch them with Get.find<...>().
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register the auth service ONCE. permanent:true keeps it alive for the
    // app's whole lifetime (auth state should never be thrown away). Every
    // Get.find<KeycloakAuthService>() returns THIS same instance.
    final authService = Get.put<KeycloakAuthService>(
      KeycloakAuthService(),
      permanent: true,
    );

    Get.put(AuthController());

    // Build the shared HTTP client, handing it the shared auth service so the
    // interceptor and the login/logout screens all use the same token store.
    // onSessionExpired/onPermissionDenied are how `core` (which owns no
    // navigation stack or UI) tells the app to react — see AuthInterceptor's
    // doc comment.
    final apiService = ApiService(
      authService,
      onSessionExpired: () => Get.offAllNamed(AppRoutes.login),
      onPermissionDenied: (serverMessage) => AppSnackbar.error(
        ErrorStrings.permissionDeniedTitle,
        serverMessage ?? ErrorStrings.permissionDeniedBody,
      ),
    );

    Get.put<ApiService>(apiService, permanent: true);

    // All these services share the one authenticated apiService above.
    final foodOfferService = FoodOfferService(apiService);
    final favoritesOfferService = FavoriteOfferService(apiService);
    final orderService = OrderService(apiService);
    final addressService = AddressService(apiService);
    final businessPartnerService = BusinessPartnerService(apiService);
    final dashboardService = DashboardService(apiService);
    Get.put<DashboardService>(dashboardService, permanent: true);
    final reviewService = ReviewService(apiService);
    final imageService = ImageService(apiService);
    Get.put<ImageService>(imageService, permanent: true);
    final productService = ProductService(apiService);
    Get.put<ProductService>(productService, permanent: true);
    final productOrderService = ProductOrderService(apiService);
    Get.put<ProductOrderService>(productOrderService, permanent: true);
    final userService = UserService(apiService);
    Get.put<UserService>(userService, permanent: true);
    Get.put<MercureController>(MercureController(userService), permanent: true);
    Get.put<ChangePasswordService>(
      ChangePasswordService(apiService),
      permanent: true,
    );
    Get.put<PushNotificationService>(
      PushNotificationService(),
      permanent: true,
    );
    Get.put<NotificationController>(
      NotificationController(NotificationService(apiService)),
      permanent: true,
    );

    // --- Controllers ---

    // fenix:true = if the controller gets disposed (e.g. when logout calls
    // Get.offAllNamed and tears down the main screen), it's automatically
    // recreated the next time it's requested. Without this, logging back in
    // after logout throws "NavigationController not found".
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );

    // put + permanent = created now and kept forever (location is needed app-wide).
    Get.put<LocationController>(LocationController(), permanent: true);

    // Each controller gets the service it depends on.
    Get.lazyPut<FoodOfferController>(
      () => FoodOfferController(foodOfferService),
      fenix: true,
    );

    Get.lazyPut<FavoritesOfferController>(
      () => FavoritesOfferController(favoritesOfferService),
      fenix: true,
    );

    Get.lazyPut<OrderController>(
      () => OrderController(orderService),
      fenix: true,
    );

    // Shared across every market — a cart is scoped to one business at a
    // time, not one market, so Food and Cosmetic product-detail screens both
    // add into this same instance. Permanent (not lazy/fenix): a cart must
    // survive arbitrary browsing between screens, unlike a per-flow
    // controller such as AddressController — lazyPut+fenix gets silently
    // disposed and recreated empty once nothing on screen is using it,
    // which was actually observed wiping items added just before navigating
    // away to add a second one.
    Get.put<CartController>(CartController(), permanent: true);

    // fenix:true = if this controller is disposed, it's automatically
    // recreated next time it's requested (good for screens you revisit).
    Get.lazyPut<AddressController>(
      () => AddressController(addressService),
      fenix: true,
    );

    Get.lazyPut<BusinessOrderController>(
      () => BusinessOrderController(orderService),
      fenix: true,
    );

    Get.lazyPut<BusinessOfferController>(
      () => BusinessOfferController(foodOfferService),
      fenix: true,
    );

    Get.lazyPut<BusinessPartnerController>(
      () => BusinessPartnerController(businessPartnerService),
      fenix: true,
    );

    Get.lazyPut<DashboardController>(
      () => DashboardController(dashboardService, userService),
      fenix: true,
    );

    // Generic Product pipeline — every market beyond Food shares
    // ProductService/ProductOrderService (registered above); each market
    // gets its own tagged ProductController/BusinessProductController
    // instance instead of a market-specific subclass. Cosmetic is the first
    // consumer; a future market would add one more tagged pair here.
    Get.lazyPut<ProductController>(
      () => ProductController(productService, market: Market.cosmetic.value),
      tag: Market.cosmetic.value,
      fenix: true,
    );

    Get.lazyPut<ProductController>(
      () => ProductController(productService, market: Market.food.value),
      tag: Market.food.value,
      fenix: true,
    );

    Get.lazyPut<BusinessProductController>(
      () => BusinessProductController(
        productService,
        market: Market.cosmetic.value,
      ),
      tag: Market.cosmetic.value,
      fenix: true,
    );

    Get.lazyPut<BusinessProductController>(
      () =>
          BusinessProductController(productService, market: Market.food.value),
      tag: Market.food.value,
      fenix: true,
    );

    // Not market-tagged — one shared checkout/order-history controller for
    // every non-Food market, since a product-order references a specific
    // Product (any market) rather than being scoped to one itself.
    Get.lazyPut<ProductOrderController>(
      () => ProductOrderController(productOrderService),
      fenix: true,
    );

    Get.lazyPut<BusinessNavigationController>(
      () => BusinessNavigationController(),
      fenix: true,
    );

    Get.lazyPut<ReviewController>(
      () => ReviewController(
        reviewService,
        onBusinessRatingChanged: () {
          if (Get.isRegistered<BusinessPartnerController>()) {
            Get.find<BusinessPartnerController>().fetchMyPartner();
          }
        },
      ),
      fenix: true,
    );

    Get.put<BankAccountController>(
      BankAccountController(BankAccountService(apiService)),
      permanent: true,
    );

    Get.lazyPut<BusinessAddressController>(
      () => BusinessAddressController(addressService),
      fenix: true,
    );

    Get.lazyPut<BusinessAnalyticsController>(
      () => BusinessAnalyticsController(),
      fenix: true,
    );

    Get.lazyPut<BusinessEarningsController>(
      () => BusinessEarningsController(),
      fenix: true,
    );

    Get.lazyPut<AdminController>(
      () => AdminController(AdminService(apiService)),
      fenix: true,
    );

    Get.lazyPut<UserPreferencesController>(
      () => UserPreferencesController(),
      fenix: true,
    );

    Get.lazyPut<BpNotifPrefsController>(
      () => BpNotifPrefsController(),
      fenix: true,
    );

    Get.lazyPut<BpEmailPrefsController>(
      () => BpEmailPrefsController(),
      fenix: true,
    );
  }

  /// Delete every user-scoped controller so that after logout the next
  /// `Get.find<T>()` recreates it fresh (calls onInit → fetchXxx) for the
  /// newly logged-in user. Safe to call even if a controller was never
  /// instantiated (`Get.delete` is a no-op for unknown types).
  static void clearUserControllers() {
    // Permanent (not lazy/fenix) — InitialBinding only runs once at app
    // startup, so Get.delete would remove it forever. Reset its state
    // in place instead, so the next login fetches a token scoped to
    // whoever just logged in rather than reusing the previous user's.
    if (Get.isRegistered<MercureController>()) {
      Get.find<MercureController>().clear();
    }
    // Permanent, same reasoning as MercureController above — reset in place
    // rather than delete, so a different account logging in on this device
    // doesn't see the previous user's cart.
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().clear();
    }
    Get.delete<NavigationController>(force: true);
    Get.delete<FoodOfferController>(force: true);
    Get.delete<ProductController>(force: true);
    Get.delete<FavoritesOfferController>(force: true);
    Get.delete<OrderController>(force: true);
    Get.delete<AddressController>(force: true);
    Get.delete<BusinessOrderController>(force: true);
    Get.delete<BusinessOfferController>(force: true);
    // clear() before delete — it also purges the on-disk 'business_partner'
    // cache entry (DataCacheService), not just the in-memory Rx state.
    // Without this, a different business-partner account logging in on the
    // same device would still see the previous partner's cached data (and
    // logo avatar) flash before the fresh fetch resolves.
    if (Get.isRegistered<BusinessPartnerController>()) {
      Get.find<BusinessPartnerController>().clear();
    }
    Get.delete<BusinessPartnerController>(force: true);
    Get.delete<DashboardController>(force: true);
    Get.delete<ProductController>(tag: Market.cosmetic.value, force: true);
    Get.delete<BusinessProductController>(
      tag: Market.cosmetic.value,
      force: true,
    );
    Get.delete<ProductOrderController>(force: true);
    Get.delete<BusinessNavigationController>(force: true);
    Get.delete<ReviewController>(force: true);
    Get.delete<BusinessAddressController>(force: true);
    Get.delete<BusinessAnalyticsController>(force: true);
    Get.delete<BusinessEarningsController>(force: true);
    Get.delete<AdminController>(force: true);
    Get.delete<BankAccountController>(force: true);
    Get.delete<UserPreferencesController>(force: true);
    Get.delete<BpNotifPrefsController>(force: true);
    Get.delete<BpEmailPrefsController>(force: true);
  }
}
