// Customer product-detail screen for the Cosmetic market. Thin wiring layer
// over the generic ProductDetailScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/product_detail_screen.dart)
// — the same generic screen Food's CustomerProductDetailScreen wires up.
// This file owns everything Cosmetic-specific: the ProductModel, the
// business's live open/closed status, distance-to-user and the "buy now"
// navigation into CosmeticCheckoutScreen.
//
// Unlike Food, there is no per-product Mercure stock topic yet (only
// `food-offers/{id}` exists on the backend today), so this screen shows a
// static stock snapshot from [ProductModel] rather than a live one — only
// the business's open/closed status updates live, via the market-agnostic
// `business-partners/{id}/status` topic. Cosmetic also has no favorites
// feature yet, so [ProductDetailConfig.favoriteButton] is left null; the
// generic screen simply omits that button.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_app/constants/add_to_cart/cart_strings.dart';
import 'package:food_app/controllers/cart_controller.dart';
import 'package:food_app/models/cart_item.dart';
import 'package:food_app/screens/add_to_cart/views/cart_conflict_dialog.dart';
import 'package:food_app/screens/add_to_cart/views/cart_screen.dart';
import 'package:food_app/constants/cosmetic/cosmetic_strings.dart';
import 'package:food_app/screens/cosmetic_teil/orders/views/cosmetic_checkout_screen.dart';
import 'package:food_app/constants/food/customer_constants/product_detail_strings.dart';
import 'package:food_app/controllers/location_controller.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:food_app/screens/food_teil/customer_views/business_reviews_screen.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/product_detail_screen.dart';
import 'package:food_app/services/mercure_service.dart';
import 'package:food_app/services/product_service.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'package:food_app/utils/distance_helper.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/widgets/dialog/info_dialog.dart';
import 'package:get/get.dart';

class CustomerCosmeticProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const CustomerCosmeticProductDetailScreen({super.key, required this.product});

  @override
  State<CustomerCosmeticProductDetailScreen> createState() =>
      _CustomerCosmeticProductDetailScreenState();
}

class _CustomerCosmeticProductDetailScreenState
    extends State<CustomerCosmeticProductDetailScreen> {
  static const _tag = 'CustomerCosmeticProductDetailScreen';
  static const _mercure = MercureService();

  late ProductModel _product;

  // Null until a business-partners/{id}/status event arrives, at which point
  // it takes precedence over the isActive/closedAt snapshot baked into
  // _product.businessPartner (see CustomerProductDetailScreen — same topic,
  // same reasoning, shared across every market).
  BusinessStatusMercureEvent? _liveStatus;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _product = widget.product;

    final businessId = int.tryParse(_product.businessPartner?.id ?? '');
    if (businessId != null) {
      _statusSub = _mercure.subscribeToBusinessStatus(
        businessId: businessId,
        onStatus: (status) {
          if (!mounted) return;
          AppLogger.info(
            _tag,
            'Mercure: business $businessId status → '
            'isActive=${status.isActive} closedAt=${status.closedAt}',
          );
          setState(() => _liveStatus = status);
        },
      );
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  void _showStoreClosedDialog() {
    InfoDialog.show(
      context,
      icon: Icons.storefront_outlined,
      iconColor: AppColors.warningDark,
      title: ProductDetailStrings.restaurantClosed,
      body: ProductDetailStrings.restaurantClosedBody,
      buttonLabel: ProductDetailStrings.gotIt,
    );
  }

  Future<void> _addToCart() async {
    final bp = _product.businessPartner;
    final isBusinessActive = _liveStatus?.isActive ?? bp?.isActive ?? false;
    final isBusinessClosed = _liveStatus?.isClosed ?? bp?.isClosed ?? false;
    if (!isBusinessActive || isBusinessClosed) {
      _showStoreClosedDialog();
      return;
    }

    final partner = bp;
    if (partner == null) return;

    final cart = Get.find<CartController>();
    final canAdd = await confirmCartSwitch(context, cart, partner.iri);
    if (!canAdd) return;

    cart.addItem(
      businessIri: partner.iri,
      businessNameValue: partner.businessName,
      businessDeliveryFeeValue: partner.deliveryFee,
      businessAcceptsCashValue: partner.acceptsCashPayment,
      marketValue: 'cosmetic',
      item: CartItem(
        itemIri: _product.iri,
        payloadKey: 'product',
        title: _product.title,
        imageUrl: _product.images.isNotEmpty ? _product.images.first.url : null,
        unitPrice: _product.isWeightBased
            ? (_product.pricePerKg ?? 0)
            : (double.tryParse(_product.price ?? '0') ?? 0),
        isWeightBased: _product.isWeightBased,
        maxQuantity: (_product.quantityAvailable ?? 1).toDouble(),
        maxWeightKg: _product.weightAvailableKg ?? 1,
        minWeightKg: _product.minOrderKg ?? 0.1,
        checkAvailability: () =>
            Get.find<ProductService>().checkCartAvailability(_product.iri),
      ),
    );

    if (!mounted) return;
    // AppSnackbar has no `mainButton` slot; the old dedicated "View Cart"
    // text button is now expressed as a tap-anywhere-on-the-toast action.
    AppSnackbar.success(
      CartStrings.addedTitle,
      CartStrings.addedBody,
      onTap: () => Get.to(() => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = _product.businessPartner;
    final now = DateTime.now();
    final withinWindow =
        _product.endTime == null || !now.isAfter(_product.endTime!);
    final isOfferActive = withinWindow && !_product.isSoldOut;
    final isBusinessActive = _liveStatus?.isActive ?? bp?.isActive ?? false;
    final isBusinessClosed = _liveStatus?.isClosed ?? bp?.isClosed ?? false;
    final canOrder = isOfferActive && isBusinessActive && !isBusinessClosed;

    final locationController = Get.find<LocationController>();
    final distanceKm = DistanceHelper.calculateDistanceKm(
      locationController.userLat.value,
      locationController.userLng.value,
      bp?.latitude,
      bp?.longitude,
    );

    return ProductDetailScreen(
      config: ProductDetailConfig(
        title: _product.title,
        description: _product.description,
        images: _product.images,
        businessPartner: bp,

        categoryLabel: CosmeticStrings.categoryLabel(_product.category),
        categoryIcon: cosmeticCategoryIcon(_product.category),
        bagLabel: CosmeticStrings.categoryLabel(_product.category),
        aboutTitle: ProductStrings.aboutTitle,

        isWeightBased: _product.isWeightBased,
        originalPrice: double.tryParse(_product.originalPrice ?? ''),
        currentPrice: _product.isWeightBased
            ? _product.pricePerKg
            : double.tryParse(_product.price ?? ''),
        quantityAvailable: _product.quantityAvailable,
        weightAvailableKg: _product.weightAvailableKg,
        minOrderKg: _product.minOrderKg,

        startTime: _product.startTime,
        endTime: _product.endTime,
        distanceKm: distanceKm,

        isOfferActive: isOfferActive,
        onReserve: () {
          if (!canOrder) {
            _showStoreClosedDialog();
            return;
          }
          Get.to(() => CosmeticCheckoutScreen(product: _product));
        },
        onAddToCart: _addToCart,
        onRatingTap: bp == null
            ? null
            : () => Get.to(
                () => BusinessReviewsScreen(
                  businessPartnerId: bp.id,
                  businessName: bp.businessName,
                  averageRating: bp.rating,
                  reviewCount: bp.reviewCount,
                ),
              ),

        // No favorites feature for Cosmetic products yet — the floating
        // button row simply omits the favorite icon.
        favoriteButton: null,
        onShare: () {},
        onBack: Get.back,

        labels: ProductDetailLabels(
          location: ProductDetailStrings.location,
          moreInfo: ProductDetailStrings.moreInfo,
          getDirections: ProductDetailStrings.getDirections,
          mapUnavailable: ProductDetailStrings.mapUnavailable,
          tapViewMap: ProductDetailStrings.tapViewMap,
          addressNotAvailable: ProductDetailStrings.addressNotAvailable,
          businessRating: ProductDetailStrings.businessRating,
          noDescription: ProductDetailStrings.noDescription,
          weightBasedLabel: ProductDetailStrings.weightBased,
          pickUp: ProductDetailStrings.pickUp,
          pickupWindow: ProductDetailStrings.pickupWindow,
          from: ProductDetailStrings.from,
          until: ProductDetailStrings.until,
          today: ProductDetailStrings.today,
          tomorrow: ProductDetailStrings.tomorrow,
          reserve: ProductStrings.buyNow,
          offerEnded: ProductStrings.outOfStock,
          kgAvailableSuffix: ProductStrings.kgAvailable,
          stockLeft: ProductStrings.stockLeft,
          pricePerKgHint: ProductDetailStrings.pricePerKg,
          savePct: ProductDetailStrings.savePct,
          origValueItem: ProductDetailStrings.origValueItem,
          origValueKg: ProductDetailStrings.origValueKg,
          weekdayShort: ProductDetailStrings.weekdayShort,
          monthShort: ProductDetailStrings.monthShort,
        ),
      ),
    );
  }
}

/// Public (not file-private) so other Cosmetic screens — e.g. the order
/// list/detail cards — can use the same icon set for a thumbnail fallback
/// instead of duplicating this switch.
IconData cosmeticCategoryIcon(String cat) => switch (cat.toLowerCase()) {
  'skincare' => Icons.spa_outlined,
  'makeup' => Icons.brush_outlined,
  'haircare' => Icons.content_cut_rounded,
  _ => Icons.auto_awesome_outlined,
};
