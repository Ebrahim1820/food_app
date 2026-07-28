import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:models/models.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

// Heart icon — toggles this offer in/out of the user's favourites.
class FavouriteButton extends StatelessWidget {
  final ProductModel offer;

  const FavouriteButton({super.key, required this.offer});

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
