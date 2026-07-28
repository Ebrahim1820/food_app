import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:auth/auth.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:core/core.dart';
import 'package:food_app/screens/shared/settings_screen.dart';
import 'package:food_app/screens/cosmetic_teil/business_views/create_product_screen.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/controllers/prodcuct_controllers/business_product_controller.dart';
import 'package:models/models.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/app_drawer.dart';
import 'package:food_app/widgets/uploadable_avatar.dart';

/// Business partner's "My Products" screen for Cosmetics — the market's
/// minimal business-side dashboard entry point, mirroring `BusinessMenuScreen`
/// (Food) at a smaller scope (no earnings/analytics/team management for
/// Cosmetics yet — out of scope for this pass).
///
/// A plain [StatelessWidget]: all state (list, filters, pagination) lives in
/// [BusinessProductController], read here via `Obx`.
class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  BusinessProductController get _c =>
      Get.find<BusinessProductController>(tag: 'cosmetic');

  int _resolvePartnerId() => Get.find<BusinessPartnerController>().partnerId;

  /// Lets this business partner/staff account browse the app as a plain
  /// customer — in Food, in Cosmetic, or switch straight to a different
  /// market's tile — instead of being stuck on this screen. Mirrors
  /// `BusinessDashboardScreen._switchToCustomerView()` (Food's equivalent).
  void _switchToCustomerView() {
    Get.back(); // close the drawer — AppDrawer's role badge doesn't auto-pop
    final nav = Get.find<NavigationController>();
    nav.actingAsCustomer.value = true;
    nav.activeMarket.value = null;
    nav.currentIndex.value = 0;
    Get.offNamed(AppRoutes.dashboard);
  }

  void _handleMenu(String value) {
    switch (value) {
      case 'settings':
        Get.to(() => const SettingsScreen());
    }
  }

  Widget _buildDrawer() {
    return Obx(() {
      final authController = Get.find<AuthController>();
      final partner = Get.find<BusinessPartnerController>().partner.value;
      final initials = partner?.businessName.isNotEmpty == true
          ? partner!.businessName.characters.first.toUpperCase()
          : '?';
      return AppDrawer(
        avatarWidget: UploadableAvatar(
          initials: initials,
          imageType: 'business_logo',
          partnerIri: partner?.iri,
          uploadPartnerIri: partner?.iri,
          size: 52,
          canUpload: true,
          backgroundColor: AppColors.white.withValues(alpha: 0.25),
          initialsColor: AppColors.white,
        ),
        userToken: authController.accessToken.value,
        roleBadge: authController.isBusinessPartner
            ? 'biz_drawer_ownerBadge'.tr
            : 'biz_drawer_memberBadge'.tr,
        onRoleBadgeTap: _switchToCustomerView,
        onMenuSelected: _handleMenu,
        sections: [
          DrawerSection(
            label: 'biz_drawer_sectionAccount'.tr,
            items: [
              DrawerItem(
                icon: Icons.settings_outlined,
                label: 'partner_settings'.tr,
                value: 'settings',
                iconColor: AppColors.gray500,
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    c.attachScrollPagination();
    final partnerId = _resolvePartnerId();
    if (partnerId != 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => c.ensureProductsLoaded(partnerId),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      // Scaffold auto-adds the hamburger button to the AppBar's leading slot
      // whenever `drawer` is set and `AppBar.leading` isn't — no extra wiring
      // needed here. Without this drawer, a Cosmetic-only business partner
      // (who lands here directly after login, see AppRoutes.businessHomeForMarkets)
      // had no way at all to reach the Dashboard to browse Food, or even
      // browse Cosmetic as a plain customer.
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.navy,
        title: Text(BusinessProductStrings.myProductsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: CosmeticStrings.businessOrdersTitle,
            onPressed: () => Get.to(
              () => CosmeticBusinessOrdersScreen(businessPartnerId: partnerId),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Obx(
                () => c.isFromCache.value
                    ? StaleBanner(onRefresh: () => c.fetchMyProducts(partnerId))
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Obx(() {
                  final isLoading =
                      c.isLoadingProducts.value && c.myProducts.isEmpty;
                  final hasError =
                      c.listError.value.isNotEmpty && c.myProducts.isEmpty;
                  final products = c.filteredProducts;

                  return RefreshIndicator(
                    onRefresh: () => c.fetchMyProducts(partnerId),
                    child: CustomScrollView(
                      controller: c.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (isLoading)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (hasError)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ErrorRetryWidget(
                              message: c.listError.value,
                              onRetry: () => c.fetchMyProducts(partnerId),
                            ),
                          )
                        else if (products.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _emptyState(context, partnerId),
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            sliver: SliverList.builder(
                              itemCount: products.length,
                              itemBuilder: (_, i) => _ProductCard(
                                product: products[i],
                                onDelete: () =>
                                    _confirmDelete(context, products[i]),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Obx(
                              () => c.isLoadingMoreProducts.value
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox(height: 96),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(BusinessProductStrings.newProductButton),
              onPressed: () => _openCreate(context, partnerId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, int partnerId) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 64,
              color: AppColors.gray600,
            ),
            const SizedBox(height: 16),
            Text(
              BusinessProductStrings.noProductsYet,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              BusinessProductStrings.emptyHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 18),
            CustomDynamicButton(
              label: BusinessProductStrings.addFirstProduct,
              icon: Icons.add,
              accentColor: AppColors.successDark,
              onPressed: () => _openCreate(context, partnerId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, int partnerId) async {
    if (partnerId == 0) {
      AppSnackbar.warning(
        BusinessProductStrings.notReadyTitle,
        BusinessProductStrings.notReadyBody,
      );
      return;
    }
    final created = await Get.to<bool>(() => const CreateProductScreen());
    if (created == true) _c.fetchMyProducts(partnerId);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductModel product,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.delete_forever_rounded,
      title: BusinessProductStrings.deleteTooltip,
      subtitle: product.title,
      body: BusinessProductStrings.couldNotDelete,
      confirmLabel: BusinessProductStrings.deleteTooltip,
      cancelLabel: BusinessProductStrings.clearFilters,
    );
    if (confirmed != true) return;

    final ok = await _c.deleteProduct(product.id);
    if (!ok) {
      AppSnackbar.error(
        BusinessProductStrings.errorSnackTitle,
        _c.updateErrorText.isNotEmpty
            ? _c.updateErrorText
            : BusinessProductStrings.couldNotDelete,
      );
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onDelete});

  final ProductModel product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final left = product.quantityAvailable ?? 0;
    final total = product.quantityTotal ?? 0;
    final soldOut = product.isSoldOut;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: BusinessProductStrings.deleteTooltip,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              CosmeticStrings.categoryLabel(product.category),
              style: const TextStyle(color: AppColors.gray600, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '€${product.price ?? product.originalPrice ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (soldOut ? AppColors.gray400 : AppColors.navy)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    soldOut
                        ? OfferStatusLabels.soldOut
                        : BusinessProductStrings.quantityLeft(left, total),
                    style: TextStyle(
                      color: soldOut ? AppColors.gray400 : AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
