// Customer product-detail screen for the Food market. Thin wiring layer over
// the generic ProductDetailScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/product_detail_screen.dart):
// this file owns everything food-specific — the FoodOfferModel, live Mercure
// subscriptions, favorites, distance-to-user, translated strings and the
// "reserve" navigation — and hands it all to the generic screen via a
// ProductDetailConfig. Other markets (cosmetic, clothes, ...) wire up their
// own detail screen the same way against the same generic screen, with their
// own model/controller, mirroring how CustomerCosmeticScreen wires
// ProductController into CustomerDiscoveryScreen for the home view.
//
// StatefulWidget so it can own two live Mercure subscriptions (public, no
// auth needed) opened on entry and closed on exit — "subscribe per screen,
// not globally":
//   - `food-offers/{offerId}`        → stock/expiry patched into [_offer]
//   - `business-partners/{id}/status` → open/closed patched into local state
// Both patch local state via setState instead of refetching the offer, so
// only the rebuilt config (and therefore only the affected badge/pill/
// button) re-renders.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:location/location.dart';
import 'business_reviews_screen.dart';
import 'package:models/models.dart';
import 'package:notification/notification.dart';
import 'package:core/core.dart';
import '../../discovery/views/product_detail_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class CustomerProductDetailScreen extends StatefulWidget {
  final ProductModel offer;

  const CustomerProductDetailScreen({super.key, required this.offer});

  @override
  State<CustomerProductDetailScreen> createState() =>
      _CustomerProductDetailScreenState();
}

class _CustomerProductDetailScreenState
    extends State<CustomerProductDetailScreen> {
  static const _tag = 'CustomerProductDetailScreen';
  static const _mercure = MercureService();

  late ProductModel _offer;

  // Live override for the business's open/closed status. Null until a
  // business-partners/{id}/status event arrives, at which point it takes
  // precedence over the isActive/closedAt snapshot baked into
  // _offer.businessPartner (which can go stale the moment the partner
  // toggles open/closed while this screen is open).
  BusinessStatusMercureEvent? _liveStatus;

  StreamSubscription? _stockSub;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;

    _stockSub = _mercure.subscribeToOfferStock(
      offerId: _offer.id,
      onStock: (stock) {
        if (!mounted) return;
        AppLogger.info(
          _tag,
          'Mercure: offer ${stock.id} stock → ${stock.status} '
          '(qty=${stock.quantityAvailable}, kg=${stock.weightAvailableKg})',
        );
        setState(() {
          _offer = _offer.copyWith(
            status: stock.status,
            quantityAvailable: stock.quantityAvailable,
            weightAvailableKg: stock.weightAvailableKg,
          );
        });
      },
    );

    final businessId = int.tryParse(_offer.businessPartner?.id ?? '');
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
    _stockSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  void _showRestaurantClosedDialog() {
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
    final bp = _offer.businessPartner;
    final isBusinessActive = _liveStatus?.isActive ?? bp?.isActive ?? false;
    final isBusinessClosed = _liveStatus?.isClosed ?? bp?.isClosed ?? false;
    if (!isBusinessActive || isBusinessClosed) {
      _showRestaurantClosedDialog();
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
      marketValue: 'food',
      item: CartItem(
        itemIri: _offer.iri,
        payloadKey: 'product',
        title: _offer.title,
        imageUrl: _offer.images.isNotEmpty ? _offer.images.first.url : null,
        unitPrice: _offer.isWeightBased
            ? (_offer.pricePerKg ?? 0)
            : (double.tryParse(_offer.price ?? '0') ?? 0),
        isWeightBased: _offer.isWeightBased,
        maxQuantity: (_offer.quantityAvailable ?? 1).toDouble(),
        maxWeightKg: _offer.weightAvailableKg ?? 1,
        minWeightKg: _offer.minOrderKg ?? 0.1,
        checkAvailability: () =>
            Get.find<ProductService>().checkCartAvailability(_offer.iri),
      ),
    );

    if (!mounted) return;
    // NOTE: original call had a `mainButton` ("View Cart" TextButton), which
    // AppSnackbar.show doesn't support. Tapping the whole toast now performs
    // the same navigation via `onTap` instead.
    AppSnackbar.success(
      CartStrings.addedTitle,
      CartStrings.addedBody,
      onTap: () => Get.to(() => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = _offer.businessPartner;
    final isOfferActive =
        _offer.endTime == null || !DateTime.now().isAfter(_offer.endTime!);
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
        title: _offer.title,
        description: _offer.description,
        images: _offer.images,
        businessPartner: bp,

        categoryLabel: FoodCategories.label(_offer.category),
        categoryIcon: _foodCategoryIcon(_offer.category),
        bagLabel: ProductDetailStrings.bagLabel(_offer.category),
        aboutTitle: ProductDetailStrings.aboutTitle(_offer.category),

        isWeightBased: _offer.isWeightBased,
        originalPrice: double.tryParse(_offer.originalPrice ?? ''),
        currentPrice: _offer.isWeightBased
            ? _offer.pricePerKg
            : double.tryParse(_offer.price ?? ''),
        quantityAvailable: _offer.quantityAvailable,
        weightAvailableKg: _offer.weightAvailableKg,
        minOrderKg: _offer.minOrderKg,

        startTime: _offer.startTime,
        endTime: _offer.endTime,
        distanceKm: distanceKm,

        isOfferActive: isOfferActive,
        onReserve: () {
          if (!canOrder) {
            _showRestaurantClosedDialog();
            return;
          }
          Get.to(() => OrderCheckoutScreen(offer: _asFoodOfferModel(_offer)));
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

        favoriteButton: _FavBtn(offer: _offer),
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
          reserve: ProductDetailStrings.reserve,
          offerEnded: ProductDetailStrings.offerEnded,
          kgAvailableSuffix: 'offer_kgAvailable'.tr,
          stockLeft: CustomerHomeOfferCardStrings.stockLeft,
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

/// Adapts a [ProductModel] to the [FoodOfferModel] shape [OrderCheckoutScreen]
/// (the single-item "Reserve" flow, shared with the Food home screen's old
/// card widgets) still expects. Built from [product]'s own fields rather than
/// round-tripping through `toJson()`/`fromJson()` — [ProductModel.toJson]
/// omits `businessPartner`/`images`, which the checkout screen needs.
FoodOfferModel _asFoodOfferModel(ProductModel product) => FoodOfferModel(
  id: product.id,
  title: product.title,
  description: product.description,
  category: product.category,
  originalPrice: product.originalPrice,
  price: product.price,
  quantityTotal: product.quantityTotal,
  quantityAvailable: product.quantityAvailable,
  isWeightBased: product.isWeightBased,
  weightTotalKg: product.weightTotalKg,
  weightAvailableKg: product.weightAvailableKg,
  pricePerKg: product.pricePerKg,
  minOrderKg: product.minOrderKg,
  startTime: product.startTime ?? DateTime.now(),
  endTime: product.endTime ?? DateTime.now(),
  status: product.status,
  images: product.images,
  businessPartner: product.businessPartner,
  createdAt: product.createdAt,
);

// Map API category key → icon (uses same keys as HomeScreen _Cat list).
IconData _foodCategoryIcon(String cat) => switch (cat.toLowerCase()) {
  'fast_food' || 'fastfood' => Icons.fastfood_rounded,
  'pizza' => Icons.local_pizza_rounded,
  'bakery' || 'bread_pastries' => Icons.breakfast_dining_rounded,
  'restaurant' || 'meals' || 'meal' => Icons.dinner_dining_rounded,
  'supermarket' || 'groceries' || 'grocery' => Icons.shopping_cart_rounded,
  'cafe' || 'caffe' => Icons.local_cafe_rounded,
  'fruits_vegetables' || 'vegetables' || 'fruit' => Icons.eco_rounded,
  'hot_drinks' || 'drinks' => Icons.local_drink_rounded,
  'cheese_dairy' => Icons.egg_alt_rounded,
  'butcher' => Icons.set_meal_rounded,
  'fish' => Icons.set_meal_rounded,
  'deli_catering' => Icons.lunch_dining_rounded,
  'flowers' || 'florist' => Icons.local_florist_rounded,
  'salads' || 'salad' || 'dessert' => Icons.spa_rounded,
  _ => Icons.shopping_bag_outlined,
};

// ── Favourite button — food-specific (FavoritesOfferController), built with
// the same circular styling every other floating button on the screen uses.
class _FavBtn extends StatelessWidget {
  final ProductModel offer;
  const _FavBtn({required this.offer});

  @override
  Widget build(BuildContext context) {
    final fav = Get.find<FavoritesOfferController>();
    return Obx(() {
      final isFav = fav.isFavorite(offer.id);
      // Removing an already-favorited sold-out item is still allowed; only
      // adding a new one is blocked — dim the icon so that's visible before
      // the tap, not just via the snackbar after.
      final blocked = !isFav && offer.isSoldOut;
      return ProductDetailCircleButton(
        onTap: () => fav.toggleFavorite(offer.id, offer: offer),
        child: Opacity(
          opacity: blocked ? 0.4 : 1.0,
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 20,
            color: isFav ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      );
    });
  }
}
