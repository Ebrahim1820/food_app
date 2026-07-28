// ─────────────────────────────────────────────────────────────────────────────
// OfferCardCompact  —  Compact horizontal / grid card
// ─────────────────────────────────────────────────────────────────────────────
//
// PURPOSE:
//   A small, fixed-height card designed for browsing offers at a glance.
//   Shows the offer image, discount badge, rating, stock level, title,
//   business name, distance from the user, pickup window, and price.
//
// USED ON:
//   • lib/screens/main_navigations/HomeScreen/customer_food_screen.dart
//       → Horizontal category rows  (SizedBox width ~170 px)
//       → Search-results 2-column grid
//
// IMPORTANT CONSTRAINT:
//   This card uses Expanded inside its Column for the info section, so it
//   REQUIRES a bounded height from its parent. Always place it inside a
//   SizedBox, GridView cell, or horizontal ListView — never directly in a
//   vertical ListView (use OfferCard for that instead).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:food_app/constants/add_to_cart/cart_strings.dart';
import 'package:food_app/controllers/cart_controller.dart';
import 'package:food_app/models/cart_item.dart';
import 'package:food_app/screens/add_to_cart/views/cart_conflict_dialog.dart';
import 'package:food_app/controllers/food_controllers/food_customer_controllers/favorites_offer_controller.dart';
import 'package:food_app/controllers/location_controller.dart';
import 'package:food_app/widgets/common/universal_adaptive_dialog.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:food_app/utils/distance_helper.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/utils/helper_methods.dart';
import 'package:food_app/widgets/common/add_to_cart_button.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/widgets/common/favourite_button.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';
import 'package:food_app/constants/food/customer_constants/customer_offer_strings.dart';
import 'package:food_app/screens/food_teil/customer_views/customer_product_detail_screen.dart';
import 'package:food_app/services/product_service.dart';
import 'package:get/get.dart';

class ProductCardCompact extends StatelessWidget {
  final ProductModel offer;

  const ProductCardCompact({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    // If endTime is null, it doesn't expire (always active).
    // Otherwise, verify current time is before the end time.
    final bool isOfferActive =
        offer.endTime == null || !DateTime.now().isAfter(offer.endTime!);
    // The restaurant must also be open and not permanently closed
    // (business-side check). Default to true when businessPartner is null to
    // avoid blocking on a data-loading race.
    final bool isBusinessActive =
        (offer.businessPartner?.isActive ?? true) &&
        !(offer.businessPartner?.isClosed ?? false);

    // The user can place an order only when both conditions are satisfied.
    final bool canOrder = isOfferActive && isBusinessActive;

    // Distinct from isBusinessActive: the shop is open but this specific
    // offer has nothing left. Blocks the tap outright rather than falling
    // into the "business closed" dialog, which doesn't apply here.
    final bool isSoldOut = offer.isSoldOut;

    final double? orig = double.tryParse(offer.originalPrice ?? '');
    final double? cur = offer.isWeightBased
        ? offer.pricePerKg
        : double.tryParse(offer.price ?? '');
    final int? savePct = (orig != null && cur != null && orig > cur)
        ? ((1 - cur / orig) * 100).round()
        : null;

    return GestureDetector(
      // Four tap outcomes:
      // • Offer ended → no tap (null disables the gesture entirely).
      // • Sold out → no tap either; there's nothing left to order.
      // • Both active → navigate to checkout.
      // • Offer active but business closed → show the inactive dialog.
      onTap: (!isOfferActive || isSoldOut)
          ? null
          : canOrder
          ? () => Get.to(() => CustomerProductDetailScreen(offer: offer))
          : () => _showBusinessInactiveDialog(context),
      child: Opacity(
        // Dim when the offer has ended OR sold out; business-inactive offers
        // stay full opacity because the deal is still valid.
        opacity: (isOfferActive && !isSoldOut) ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(context, isOfferActive, isSoldOut, savePct),
              Expanded(
                child: _buildInfo(orig, cur, Get.find<LocationController>()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a dialog explaining that the restaurant is temporarily not accepting
  /// orders. Called when the offer is valid but [isBusinessActive] is false.
  void _showBusinessInactiveDialog(BuildContext context) {
    UniversalAdaptiveDialog.show(
      context,
      icon: Icons.storefront_outlined,
      iconColor: AppColors.warningDark,
      title: BusinessInactiveDialogStrings.title,
      body: BusinessInactiveDialogStrings.body,
      actions: [DialogAction(label: BusinessInactiveDialogStrings.closeButton)],
    );
  }

  /// Quick-add straight from the card — same rules as
  /// [CustomerProductDetailScreen]'s own add-to-cart (business must be open,
  /// confirm before wiping a cart for a different business), just without
  /// that screen's live Mercure-subscribed status (falls back to the
  /// offer's own static `businessPartner` fields, same as that screen does
  /// when no live update has arrived yet).
  Future<void> _addToCart(BuildContext context) async {
    final partner = offer.businessPartner;
    if (partner == null) return;
    final isBusinessActive = partner.isActive;
    final isBusinessClosed = partner.isClosed;
    if (!isBusinessActive || isBusinessClosed) {
      _showBusinessInactiveDialog(context);
      return;
    }

    final cart = Get.find<CartController>();
    final canAdd = await confirmCartSwitch(context, cart, partner.iri);
    if (!canAdd) return;

    cart.addItem(
      businessIri: partner.iri,
      businessNameValue: partner.businessName,
      businessDeliveryFeeValue: partner.deliveryFee,
      businessAcceptsCashValue: partner.acceptsCashPayment,
      marketValue: offer.market,
      item: CartItem(
        itemIri: offer.iri,
        payloadKey: 'product',
        title: offer.title,
        imageUrl: offer.images.isNotEmpty ? offer.images.first.url : null,
        unitPrice: offer.isWeightBased
            ? (offer.pricePerKg ?? 0)
            : (double.tryParse(offer.price ?? '0') ?? 0),
        isWeightBased: offer.isWeightBased,
        maxQuantity: (offer.quantityAvailable ?? 1).toDouble(),
        maxWeightKg: offer.weightAvailableKg ?? 1,
        minWeightKg: offer.minOrderKg ?? 0.1,
        checkAvailability: () =>
            Get.find<ProductService>().checkCartAvailability(offer.iri),
      ),
    );

    if (!context.mounted) return;
    AppSnackbar.success(CartStrings.addedTitle, CartStrings.addedBody);
  }

  // ── IMAGE SECTION (fixed 120 px height) ──────────────────────────────────
  // Displays the offer's first photo with overlaid badges.
  // All badges use Stack + Positioned so they float above the image.

  Widget _buildImage(
    BuildContext context,
    bool isOfferActive,
    bool isSoldOut,
    int? savePct,
  ) {
    return SizedBox(
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Offer photo — falls back to a placeholder when no image is set.
          NetworkImageWidget(
            imageUrl: offer.images.isNotEmpty ? offer.images.first.url : null,
            fit: BoxFit.cover,
          ),

          // Subtle dark gradient at the bottom so text/badges stay readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.transparent, AppColors.shadow],
              ),
            ),
          ),

          // Discount badge — "Save X%" green pill, top-left.
          // Only shown when the sale price is lower than the original price.
          if (savePct != null)
            Positioned(
              top: 8,
              left: 8,
              child: _Pill(
                label: CustomerHomeOfferCardStrings.saveBadge(savePct),
                bgColor: AppColors.error,
                textColor: AppColors.white,
              ),
            ),

          // Rating badge — business star rating, top-right.
          // Hidden when no businessPartner is attached to the offer.
          if (offer.businessPartner != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      CurrencyFormatter.localizeDigits(
                        offer.businessPartner!.rating.toStringAsFixed(1),
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Stock badge — remaining quantity, bottom-left. Hidden once sold
          // out since the overlay below already covers the whole image.
          // Color-coded by urgency: red = 1 left, amber = ≤3, dark = plenty.
          // For weight-based offers shows available kg instead of item count.
          if (isOfferActive && !isSoldOut)
            Positioned(
              bottom: 8,
              left: 8,
              child: offer.isWeightBased
                  ? _Pill(
                      label: offer.weightAvailableKg != null
                          ? CurrencyFormatter.formatWeight(
                              offer.weightAvailableKg!,
                            )
                          : '—',
                      bgColor: AppColors.successDark,
                      textColor: AppColors.white,
                    )
                  : _StockBadge(
                      quantity: offer.quantityAvailable ?? 0,
                      total: offer.quantityTotal,
                    ),
            ),

          // Quick add-to-cart button — bottom-right, the one corner not
          // already used by another badge. Lets a browsing customer add
          // straight from the grid/row without opening the detail screen.
          if (isOfferActive && !isSoldOut)
            Positioned(
              bottom: 8,
              right: 8,
              child: AddToCartButton(onTap: () => _addToCart(context)),
            ),

          // Sold-out overlay — blurs the photo (instead of just dimming it)
          // and stamps a "Sold out" pill dead-center, so it reads clearly as
          // "gone" rather than just "less prominent" like the ended state.
          if (isOfferActive && isSoldOut)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: AppColors.black.withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child: _Pill(
                    label: OfferStatusLabels.soldOut,
                    bgColor: AppColors.white,
                    textColor: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

          // Ended overlay — dims the whole image and shows "Ended" pill
          // when the offer has expired so it's unmissable at a glance.
          if (!isOfferActive)
            Container(
              color: AppColors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: _Pill(
                label: CustomerHomeOfferCardStrings.ended,
                bgColor: AppColors.white,
                textColor: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  // ── INFO SECTION ──────────────────────────────────────────────────────────
  // Text details below the image: title, business name + distance,
  // pickup window, and sale price.
  // Uses Expanded + Spacer so the pickup/price rows always sit at the bottom
  // regardless of how many lines the title takes.

  Widget _buildInfo(
    double? orig,
    double? cur,
    LocationController locationController,
  ) {
    final bool hasDiscount = orig != null && cur != null && orig > cur;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offer title (up to 2 lines) + favourite heart button on the right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  offer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Heart icon — toggles this offer in/out of the user's favourites.
              FavouriteButton(offer: offer),
            ],
          ),
          const SizedBox(height: 3),

          // Business name (left) + distance from user (right, primary colour).
          // Distance is reactive via Obx — appears as soon as GPS is available.
          // When location is unavailable the business name fills the full width.
          Obx(() {
            final distanceKm = DistanceHelper.calculateDistanceKm(
              locationController.userLat.value,
              locationController.userLng.value,
              offer.businessPartner?.latitude,
              offer.businessPartner?.longitude,
            );
            return Row(
              children: [
                Expanded(
                  child: Text(
                    offer.businessPartner?.businessName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (distanceKm != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.near_me_outlined,
                    size: 10,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    HelperMethods.formatDistance(distanceKm),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            );
          }),

          // Pushes pickup + price rows to the bottom of the info area.
          const Spacer(flex: 2),

          // Pickup window — shows "Today · 14:00–18:00" or date range for
          // multi-day offers. Helps the user judge urgency at a glance.
          if (offer.startTime != null && offer.endTime != null)
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 11,
                  color: AppColors.gray800,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    HelperMethods.formatPickupWindow(
                      offer.startTime!,
                      offer.endTime!,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),

          // Price row — sale price (bold) with original price struck through
          // when a discount exists. Shows /kg suffix for weight-based offers.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Text(
                      offer.isWeightBased
                          ? CurrencyFormatter.perKg(
                              double.tryParse(offer.originalPrice ?? '') ?? 0,
                            )
                          : HelperMethods.formatPrice(offer.originalPrice!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray600,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  offer.isWeightBased
                      ? (offer.pricePerKg != null
                            ? CurrencyFormatter.perKg(offer.pricePerKg!)
                            : '—')
                      : HelperMethods.formatPrice(offer.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Favourite heart button ────────────────────────────────────────────────────

class _FavouriteButton extends StatelessWidget {
  final ProductModel offer;

  const _FavouriteButton({required this.offer});

  @override
  Widget build(BuildContext context) {
    final fav = Get.find<FavoritesOfferController>();
    return Obx(() {
      final isFav = fav.isFavorite(offer.id);
      // Removing an already-favorited sold-out item is still allowed; only
      // adding a new one is blocked — dim the icon so that's visible before
      // the tap, not just via the snackbar after.
      final blocked = !isFav && offer.isSoldOut;
      return GestureDetector(
        onTap: () => fav.toggleFavorite(offer.id, offer: offer),
        child: Opacity(
          opacity: blocked ? 0.4 : 1.0,
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 19,
            color: isFav ? AppColors.primary : AppColors.gray400,
          ),
        ),
      );
    });
  }
}

// ── Stock badge ───────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  final int quantity;
  final int? total;
  const _StockBadge({required this.quantity, this.total});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (quantity == 1) {
      bg = AppColors.error;
    } else if (quantity <= 3) {
      bg = AppColors.accent;
    } else {
      bg = AppColors.black.withValues(alpha: 0.45);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_rounded,
            size: 9,
            color: AppColors.white,
          ),
          const SizedBox(width: 3),
          Text(
            (total != null && total! > 0)
                ? '$quantity/$total'
                : CustomerHomeOfferCardStrings.stockLeft(quantity),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small pill label ──────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Pill({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
