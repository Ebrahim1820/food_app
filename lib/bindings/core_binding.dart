import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/services/change_password_service.dart';
import 'package:food_app/services/dashboard_service.dart';
import 'package:food_app/services/push_notification_service.dart';
import 'package:food_app/controllers/dashboard_controller.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:get/get.dart';
import 'package:i18n/i18n.dart';
import 'package:location/location.dart';
import 'package:notification/notification.dart';
import 'package:profile/profile.dart';
import 'package:review/review.dart';
import 'package:seller_mgmt/seller_mgmt.dart';

/// Auth/session, the shared HTTP client, and the API-calling *services* every
/// team's controllers are built on top of. No team owns this file alone —
/// it's the foundation layer, not a place for feature-specific registration.
/// Genuinely shared *controllers* (things more than one team's screens use,
/// like the app-shell nav state or the review controller) also live here;
/// each team's own controllers go in their own binding instead.
class CoreBinding {
  /// Services other bindings' controllers need — populated by [register]
  /// and read via the getters below rather than each binding calling
  /// `Get.find` again for a value we already have in hand while wiring up.
  static late final FoodOfferService foodOfferService;
  static late final FavoriteOfferService favoritesOfferService;
  static late final OrderService orderService;
  static late final AddressService addressService;
  static late final BusinessPartnerService businessPartnerService;
  static late final ProductService productService;
  static late final ProductOrderService productOrderService;
  static late final UserService userService;
  static late final ApiService apiService;

  static void register() {
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
    apiService = ApiService(
      authService,
      onSessionExpired: () => Get.offAllNamed(AppRoutes.login),
      onPermissionDenied: (serverMessage) => AppSnackbar.error(
        ErrorStrings.permissionDeniedTitle,
        serverMessage ?? ErrorStrings.permissionDeniedBody,
      ),
    );
    Get.put<ApiService>(apiService, permanent: true);

    // All these services share the one authenticated apiService above.
    foodOfferService = FoodOfferService(apiService);
    favoritesOfferService = FavoriteOfferService(apiService);
    orderService = OrderService(apiService);
    addressService = AddressService(apiService);
    businessPartnerService = BusinessPartnerService(apiService);
    productService = ProductService(apiService);
    productOrderService = ProductOrderService(apiService);
    userService = UserService(apiService);

    final dashboardService = DashboardService(apiService);
    Get.put<DashboardService>(dashboardService, permanent: true);
    final reviewService = ReviewService(apiService);
    final imageService = ImageService(apiService);
    Get.put<ImageService>(imageService, permanent: true);
    Get.put<ProductService>(productService, permanent: true);
    Get.put<ProductOrderService>(productOrderService, permanent: true);
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

    Get.lazyPut<DashboardController>(
      () => DashboardController(dashboardService, userService),
      fenix: true,
    );

    // Reviews are read/written from both customer and business screens —
    // genuinely shared, not owned by either team alone.
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
  }

  /// See [InitialBinding.clearUserControllers] — resets the shared,
  /// non-team-owned state that survives logout by design (permanent, not
  /// lazy/fenix), plus deletes the lazy/fenix ones so they rebuild fresh.
  static void clear() {
    if (Get.isRegistered<MercureController>()) {
      Get.find<MercureController>().clear();
    }
    Get.delete<NavigationController>(force: true);
    Get.delete<DashboardController>(force: true);
    Get.delete<ReviewController>(force: true);
  }
}
