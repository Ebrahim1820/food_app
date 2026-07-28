import 'package:get/get.dart';
import 'package:models/models.dart';
import 'package:seller_mgmt/seller_mgmt.dart';

import 'core_binding.dart';

/// Seller Platform team's controllers. Depends on services registered by
/// [CoreBinding.register] (call that first) — owns no HTTP client of its
/// own, just the business-partner-facing state built on top of it.
class SellerBinding {
  static void register() {
    Get.lazyPut<BusinessOrderController>(
      () => BusinessOrderController(CoreBinding.orderService),
      fenix: true,
    );

    Get.lazyPut<BusinessOfferController>(
      () => BusinessOfferController(CoreBinding.foodOfferService),
      fenix: true,
    );

    Get.lazyPut<BusinessPartnerController>(
      () => BusinessPartnerController(CoreBinding.businessPartnerService),
      fenix: true,
    );

    // Generic Product pipeline — every market beyond Food shares
    // ProductService (registered in CoreBinding); each market gets its own
    // tagged BusinessProductController instance instead of a market-specific
    // subclass. Cosmetic is the first consumer.
    Get.lazyPut<BusinessProductController>(
      () => BusinessProductController(
        CoreBinding.productService,
        market: Market.cosmetic.value,
      ),
      tag: Market.cosmetic.value,
      fenix: true,
    );

    Get.lazyPut<BusinessProductController>(
      () => BusinessProductController(
        CoreBinding.productService,
        market: Market.food.value,
      ),
      tag: Market.food.value,
      fenix: true,
    );

    Get.lazyPut<BusinessNavigationController>(
      () => BusinessNavigationController(),
      fenix: true,
    );

    Get.put<BankAccountController>(
      BankAccountController(BankAccountService(CoreBinding.apiService)),
      permanent: true,
    );

    Get.lazyPut<BusinessAddressController>(
      () => BusinessAddressController(CoreBinding.addressService),
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

    Get.lazyPut<BpNotifPrefsController>(
      () => BpNotifPrefsController(),
      fenix: true,
    );

    Get.lazyPut<BpEmailPrefsController>(
      () => BpEmailPrefsController(),
      fenix: true,
    );
  }

  static void clear() {
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
    Get.delete<BusinessProductController>(
      tag: Market.cosmetic.value,
      force: true,
    );
    Get.delete<BusinessNavigationController>(force: true);
    Get.delete<BusinessAddressController>(force: true);
    Get.delete<BusinessAnalyticsController>(force: true);
    Get.delete<BusinessEarningsController>(force: true);
    Get.delete<BankAccountController>(force: true);
    Get.delete<BpNotifPrefsController>(force: true);
    Get.delete<BpEmailPrefsController>(force: true);
  }
}
