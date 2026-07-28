// ─────────────────────────────────────────────────────────────────────────────
// OfferCard  —  Full-width vertical list card
// ─────────────────────────────────────────────────────────────────────────────
//
// PURPOSE:
//   A large, full-width card for displaying a single offer in a vertical list.
//   Shows offer image, status badge, rating, category, title, favourite button,
//   business name, distance + location (tappable → opens Maps), sale price,
//   pickup window, and a primary CTA button (Reserve / Order Now).
//
// USED ON:
//   • lib/screens/main_navigations/FavoritesScreen/favorites_screen.dart
//       → Vertical ListView of the user's saved favourite offers
//
// IMPORTANT CONSTRAINT:
//   This card is self-sizing — it does NOT use Expanded internally, so it
//   works correctly inside a vertical ListView with unbounded height.
//   Do NOT use OfferCardCompact in a vertical ListView (it will collapse).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_customer_controllers/favorites_offer_controller.dart';
import 'package:food_app/controllers/location_controller.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/widgets/common/universal_adaptive_dialog.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/utils/distance_helper.dart';
import 'package:food_app/utils/map_helper.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/constants/food/customer_constants/customer_favorites_strings.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';
import 'package:food_app/utils/helper_methods.dart';
import 'package:food_app/constants/food/customer_constants/customer_offer_strings.dart';
import 'package:food_app/screens/food_teil/customer_views/customer_product_detail_screen.dart';
import 'package:get/get.dart';

class ProductCard extends StatelessWidget {
  final ProductModel offer;

  const ProductCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    // Access business partner info safely
    final business = offer.businessPartner;

    // Access the favorites controller to manage favorite offers
    final favoritesController = Get.find<FavoritesOfferController>();

    // Access the location controller to get user's current location for distance calculation
    final locationController = Get.find<LocationController>();

    //final bool isExpired = DateTime.now().isAfter(offer.endTime);
    final bool isExpired =
        offer.endTime != null && DateTime.now().isAfter(offer.endTime!);

    // The offer itself must be live (not expired and status == 'active').
    final bool isOfferActive = !isExpired && offer.status == 'active';

    // The restaurant must also be open (and not permanently closed). Default
    // to true when businessPartner is null so we don't block orders on a
    // data-loading race.
    final bool isBusinessActive =
        (business?.isActive ?? true) && !(business?.isClosed ?? false);

    // The user can only order when BOTH conditions are met.
    final bool canOrder = isOfferActive && isBusinessActive;

    // Distinct from isBusinessActive: the shop is open but this specific
    // offer has nothing left.
    final bool isSoldOut = offer.isSoldOut;

    // This card is only ever shown for offers the user has favorited (see
    // the class doc), so a sold-out item here isn't a dead end — the user
    // is already subscribed to a "back in stock" alert for it. Used to swap
    // the disabled "Sold out" treatment for a "we'll notify you" one below.
    final bool isFavoriteOffer = favoritesController.isFavorite(offer.id);

    final imageHeight = (MediaQuery.of(context).size.height * 0.28).clamp(
      110.0,
      190.0,
    );

    return Obx(() {
      // True for a few seconds right after a live Mercure update flips this
      // offer from sold-out to available while this screen is open — see
      // FavoritesOfferController._onStockEvent. Highlights the card so the
      // restock doesn't just silently blend back into the list.
      final bool justRestocked = favoritesController.justRestockedIds.contains(
        offer.id,
      );

      return Opacity(
        // Dim the card when the offer itself has ended/expired or sold out.
        // Business-inactive offers stay full opacity because the deal is still valid
        // — the restaurant just isn't accepting orders right now.
        opacity: (isOfferActive && !isSoldOut) ? 1 : 0.55,

        child: Container(
          margin: const EdgeInsets.only(bottom: 18),

          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: justRestocked
                ? Border.all(color: AppColors.success, width: 2)
                : null,

            boxShadow: [
              BoxShadow(
                color: justRestocked
                    ? AppColors.success.withValues(alpha: 0.28)
                    : AppColors.black.withValues(alpha: 0.05),
                blurRadius: justRestocked ? 22 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ── IMAGE SECTION ──────────────────────────────────────────────
              // Rounded-top photo with four overlaid badges via Stack+Positioned.
              // Height scales with screen size (28% of screen, clamped 110–190px).
              Stack(
                children: [
                  // Offer photo — rounded only on the top corners to blend with
                  // the card shape. Falls back to placeholder when no image set.
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: NetworkImageWidget(
                      imageUrl: offer.images.isNotEmpty
                          ? offer.images.first.url
                          : null,
                      height: imageHeight,
                    ),
                  ),

                  // Sold-out overlay — blurs the photo and stamps a "Sold out"
                  // pill dead-center so it reads as "gone", not just "dimmer".
                  if (isOfferActive && isSoldOut)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Container(
                            height: imageHeight,
                            color: AppColors.black.withValues(alpha: 0.3),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    OfferStatusLabels.soldOut,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  // Reassures the user their favorite isn't a
                                  // dead end — favoriting an offer already
                                  // subscribes them to a "back in stock" alert,
                                  // so this just makes that promise visible.
                                  if (isFavoriteOffer) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.notifications_active_rounded,
                                            size: 13,
                                            color: AppColors.successDark,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            CustomerOfferCardStrings
                                                .notifyBadge,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.successDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Star rating badge — business average rating, top-right.
                  // Hidden when no businessPartner is attached to the offer
                  // (matches OfferCardCompact's same guard — `business!` here
                  // used to crash with a null-check error whenever it was null,
                  // e.g. right after a favorite loads before its business data
                  // has resolved).
                  if (business != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              CurrencyFormatter.localizeDigits(
                                business.rating.toStringAsFixed(1),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Dark gradient overlay — makes top-left status badge readable
                  // against any image colour.
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.black.withValues(alpha: 0.05),
                            AppColors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Availability badge — top-left, four possible labels:
                  //   "Available"          → offer active + restaurant open
                  //   "Sold out"           → offer active, nothing left
                  //   "Temporarily Closed" → offer active, restaurant closed
                  //   "Ended"              → offer expired
                  // Skipped when the sold-out stamp is already covering the
                  // image — showing both would be redundant.
                  if (!isSoldOut)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: justRestocked
                              ? AppColors.success
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (justRestocked) ...[
                              const Icon(
                                Icons.celebration_rounded,
                                size: 13,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              justRestocked
                                  ? CustomerFavoritesStrings.backInStockBadge
                                  : !isOfferActive
                                  ? CustomerOfferCardStrings.ended
                                  : !isBusinessActive
                                  ? CustomerOfferCardStrings.businessClosed
                                  : CustomerOfferCardStrings.available,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: justRestocked
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // ── CONTENT SECTION ────────────────────────────────────────────
              // All text details below the image.
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food category label (e.g. "Bakery", "Fast food").
                    Text(
                      HelperMethods.capitalizeFirst(offer.category),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),

                    // Offer title (up to 2 lines) + favourite heart button.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Heart button — saves/unsaves this offer to favourites.
                        // Uses Obx so it reacts instantly when toggled.
                        Obx(() {
                          final isFavorite = favoritesController.isFavorite(
                            offer.id,
                          );
                          // Removing an already-favorited sold-out item is
                          // still allowed; only adding a new one is blocked —
                          // dim the icon so that's visible before the tap.
                          final blocked = !isFavorite && isSoldOut;
                          return Opacity(
                            opacity: blocked ? 0.4 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  await favoritesController.toggleFavorite(
                                    offer.id,
                                    offer: offer,
                                  );
                                },
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? AppColors.error : null,
                                ),
                                iconSize: 35,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Business (restaurant / store) name with storefront icon.
                    // Hidden when no businessPartner is attached to the offer —
                    // same reasoning as the rating badge above.
                    if (business != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              business.businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (business != null) const SizedBox(height: 5),

                    // Distance chip + city/street row — tapping opens Maps.
                    // Uses Obx so the distance chip appears as soon as the GPS
                    // fix arrives without requiring a full card rebuild.
                    //   • When location available: [↗ 1.2 km]  📍 Amsterdam
                    //   • When no location:                     📍 Main Street
                    // Hidden entirely when no businessPartner is attached —
                    // same reasoning as the rating badge above.
                    if (business != null)
                      Obx(() {
                        final distanceKm = DistanceHelper.calculateDistanceKm(
                          locationController.userLat.value,
                          locationController.userLng.value,
                          business.latitude,
                          business.longitude,
                        );
                        return GestureDetector(
                          onTap: () => MapHelper.openMap(
                            latitude: double.parse(business.latitude),
                            longitude: double.parse(business.longitude),
                          ),
                          child: Row(
                            children: [
                              // Distance chip — only shown when GPS is available.
                              if (distanceKm != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.near_me_outlined,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        HelperMethods.formatDistance(
                                          distanceKm,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // City name when distance is known, street otherwise.
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  distanceKm != null
                                      ? (business.city.isNotEmpty
                                            ? business.city
                                            : CustomerOfferCardStrings.noCity)
                                      : business.street.isNotEmpty
                                      ? business.street
                                      : CustomerOfferCardStrings.noAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 8),

                    // Price row — sale price, original strikethrough, discount %.
                    // Handles both piece-based (€4.99) and weight-based (€3.50/kg).
                    _OfferCardPriceRow(offer: offer),

                    const SizedBox(height: 5),

                    // Pickup window — "Today · 14:00–18:00" or full date range
                    // for multi-day offers. Same logic as the detail screen.
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          HelperMethods.formatPickupWindow(
                            offer.startTime,
                            offer.endTime,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // CTA button — primary action for this card.
                    // Label and enabled state reflect the current offer + business status:
                    //   "Order Now"          → both active, navigates to detail screen
                    //   "Sold out"           → offer valid, nothing left, button disabled
                    //   "Temporarily Closed" → offer valid but restaurant not accepting orders
                    //   "Unavailable"        → offer has expired, button disabled
                    // Sold-out favorite gets a distinct "notified" CTA instead
                    // of a plain disabled button — same disabled state, but it
                    // reads as "you're covered" rather than a dead end.
                    SizedBox(
                      width: double.infinity,
                      child: (isOfferActive && isSoldOut && isFavoriteOffer)
                          ? ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(
                                Icons.notifications_active_rounded,
                                size: 18,
                              ),
                              label: Text(
                                CustomerOfferCardStrings.notifyMeButton,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successLight,
                                foregroundColor: AppColors.successDark,
                                disabledBackgroundColor: AppColors.successLight,
                                disabledForegroundColor: AppColors.successDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            )
                          : CustomDynamicButton(
                              borderRadius: 16,
                              label: !isOfferActive
                                  ? CustomerOfferCardStrings.unavailable
                                  : isSoldOut
                                  ? OfferStatusLabels.soldOut
                                  : canOrder
                                  ? CustomerOfferCardStrings.orderNow
                                  : CustomerOfferCardStrings.businessClosed,
                              onPressed: (!isOfferActive || isSoldOut)
                                  ? null
                                  : canOrder
                                  ? () => Get.to(
                                      () => CustomerProductDetailScreen(
                                        offer: offer,
                                      ),
                                    )
                                  : () => _showBusinessInactiveDialog(context),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Shows a dialog explaining that the restaurant is temporarily not accepting
  /// orders. Called when the offer is valid but [isBusinessActive] is false.
  void _showBusinessInactiveDialog(BuildContext context) {
    // Storefront icon with a warning colour to signal "closed, not gone".
    UniversalAdaptiveDialog.show(
      context,
      icon: Icons.storefront_outlined,
      iconColor: AppColors.warningDark,
      title: BusinessInactiveDialogStrings.title,
      body: BusinessInactiveDialogStrings.body,
      actions: [DialogAction(label: BusinessInactiveDialogStrings.closeButton)],
    );
  }
}

class _OfferCardPriceRow extends StatelessWidget {
  const _OfferCardPriceRow({required this.offer});
  final ProductModel offer;

  @override
  Widget build(BuildContext context) {
    if (offer.isWeightBased) {
      final perKg = offer.pricePerKg ?? 0;
      final origPerKg = double.tryParse(offer.originalPrice ?? '') ?? 0;
      final pct = (origPerKg > 0 && perKg < origPerKg)
          ? ((1 - perKg / origPerKg) * 100).round()
          : 0;
      final weightKg = offer.weightAvailableKg ?? 0;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            CurrencyFormatter.perKg(perKg),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.successDark,
            ),
          ),
          if (origPerKg > perKg) ...[
            const SizedBox(width: 8),
            Text(
              CurrencyFormatter.perKg(origPerKg),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray400,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.gray400,
              ),
            ),
          ],
          if (pct > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                CustomerOfferCardStrings.saveBadge(pct),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.successDark,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            CurrencyFormatter.formatWeight(weightKg),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final deal = double.tryParse(offer.price ?? '') ?? 0;
    final orig = double.tryParse(offer.originalPrice ?? '') ?? 0;
    final pct = (orig > 0 && deal < orig)
        ? ((1 - deal / orig) * 100).round()
        : 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          CurrencyFormatter.format(deal),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.successDark,
          ),
        ),
        if (orig > deal) ...[
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(orig),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.gray400,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.gray400,
            ),
          ),
        ],
        if (pct > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              CustomerOfferCardStrings.saveBadge(pct),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.successDark,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
