import 'package:customer_experience/customer_experience.dart';
import 'package:get/get.dart';
import 'package:models/models.dart';
import 'package:profile/profile.dart';

import 'core_binding.dart';

/// Customer Experience team's controllers. Depends on services registered
/// by [CoreBinding.register] (call that first) — owns no HTTP client of its
/// own, just the customer-facing state built on top of it.
class CustomerBinding {
  static void register() {
    // Each controller gets the service it depends on.
    Get.lazyPut<FoodOfferController>(
      () => FoodOfferController(CoreBinding.foodOfferService),
      fenix: true,
    );

    Get.lazyPut<FavoritesOfferController>(
      () => FavoritesOfferController(CoreBinding.favoritesOfferService),
      fenix: true,
    );

    Get.lazyPut<OrderController>(
      () => OrderController(CoreBinding.orderService),
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
      () => AddressController(CoreBinding.addressService),
      fenix: true,
    );

    // Generic Product pipeline — every market beyond Food shares
    // ProductService/ProductOrderService (registered in CoreBinding); each
    // market gets its own tagged ProductController instance instead of a
    // market-specific subclass. Cosmetic is the first consumer; a future
    // market would add one more tagged entry here.
    Get.lazyPut<ProductController>(
      () => ProductController(
        CoreBinding.productService,
        market: Market.cosmetic.value,
      ),
      tag: Market.cosmetic.value,
      fenix: true,
    );

    Get.lazyPut<ProductController>(
      () => ProductController(
        CoreBinding.productService,
        market: Market.food.value,
      ),
      tag: Market.food.value,
      fenix: true,
    );

    // Not market-tagged — one shared checkout/order-history controller for
    // every non-Food market, since a product-order references a specific
    // Product (any market) rather than being scoped to one itself.
    Get.lazyPut<ProductOrderController>(
      () => ProductOrderController(CoreBinding.productOrderService),
      fenix: true,
    );

    Get.lazyPut<UserPreferencesController>(
      () => UserPreferencesController(),
      fenix: true,
    );
  }

  static void clear() {
    Get.delete<FoodOfferController>(force: true);
    Get.delete<ProductController>(force: true);
    Get.delete<FavoritesOfferController>(force: true);
    Get.delete<OrderController>(force: true);
    Get.delete<AddressController>(force: true);
    Get.delete<ProductController>(tag: Market.cosmetic.value, force: true);
    Get.delete<ProductOrderController>(force: true);
    Get.delete<UserPreferencesController>(force: true);
    // Permanent, not lazy/fenix — reset in place rather than delete, so a
    // different account logging in on this device doesn't see the previous
    // user's cart.
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().clear();
    }
  }
}
