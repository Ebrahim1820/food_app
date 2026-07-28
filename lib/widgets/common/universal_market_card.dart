import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/favourite_button.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';

/// Generic photo-forward product card for market catalogs — accepts
/// colours/content as parameters instead of each market screen hand-rolling
/// its own card. Image fills the top ~60% of the card, details sit below,
/// matching the polished look of Food's `OfferCardCompact` but market-agnostic
/// (no offer-specific fields like pickup windows or stock counts). Pass
/// [imageUrl] for a photo-backed listing, or [leadingIcon] for markets
/// without photos yet — a large accent-tinted icon fills the image area
/// instead.
///
/// The favorite heart is opt-in: pass [onFavoriteTap] to show it (mirrors
/// Food's `OfferCardCompact` placement, next to the title) or leave it null
/// to hide it entirely — for markets with no favorites backend yet (e.g.
/// Cosmetic today), this widget has no opinion on where favorite state comes
/// from; the caller owns that entirely.
class UniversalMarketCard extends StatelessWidget {
  const UniversalMarketCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.leadingIcon,
    this.accentColor = AppColors.primary,
    this.trailingLabel,
    this.badgeLabel,
    this.onTap,
    this.isFavorite = false,
    this.favoriteDimmed = false,
    this.onFavoriteTap,
  }) : assert(
         imageUrl != null || leadingIcon != null,
         'Provide either imageUrl or leadingIcon',
       );

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final IconData? leadingIcon;
  final Color accentColor;
  final String? trailingLabel;
  final String? badgeLabel;
  final VoidCallback? onTap;

  /// Whether the heart renders filled. Ignored (and the heart hidden
  /// entirely) when [onFavoriteTap] is null.
  final bool isFavorite;

  /// Dims the heart — e.g. while adding a sold-out item is blocked but
  /// removing an already-favorited one still isn't. Purely visual; the tap
  /// itself is never disabled here, matching Food's card (the callback
  /// decides whether to act on it).
  final bool favoriteDimmed;

  /// Null hides the heart button entirely.
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
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
              // Adjusted ratio to give info area adequate height
              Expanded(flex: 60, child: _buildImage()),
              Expanded(flex: 40, child: _buildInfo()),
            ],
          ),
        ),
      ),
    );
  }

  // ── IMAGE SECTION (top ~60% of the card) ──────────────────────────────────

  Widget _buildImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl!.isNotEmpty)
          NetworkImageWidget(imageUrl: imageUrl, fit: BoxFit.cover)
        else
          Container(
            color: accentColor.withValues(alpha: 0.10),
            alignment: Alignment.center,
            child: Icon(leadingIcon, color: accentColor, size: 40),
          ),

        if (badgeLabel != null && badgeLabel!.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            child: _Pill(
              label: badgeLabel!,
              bgColor: accentColor,
              textColor: AppColors.white,
            ),
          ),
      ],
    );
  }

  // ── INFO SECTION (bottom ~40% of the card) ─────────────────────────────────

  Widget _buildInfo() {
    return Padding(
      // Reduced top/bottom padding slightly (from 9/10 to 6/6)
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  // If space is tight, restrict to 1-2 lines or reduce font scale
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onFavoriteTap != null) ...[
                const SizedBox(width: 4),
                _FavoriteButton(
                  isFavorite: isFavorite,
                  dimmed: favoriteDimmed,
                  onTap: onFavoriteTap!,
                ),
                // FavouriteButton()
              ],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (trailingLabel != null && trailingLabel!.isNotEmpty)
            Text(
              trailingLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Favorite heart button ────────────────────────────────────────────────────

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final bool dimmed;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.4 : 1.0,
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 17,
          color: isFavorite ? AppColors.primary : AppColors.gray400,
        ),
      ),
    );
  }
}

// ── Small pill label (category badge) ──────────────────────────────────────

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
