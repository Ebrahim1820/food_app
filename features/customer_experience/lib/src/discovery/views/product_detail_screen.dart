// Generic customer product-detail screen — expandable hero image, info rows
// (category / rating / distance / pickup window / weight), location card,
// description, savings banner and a sticky reserve/buy bottom bar.
//
// Reusable across markets the same way CustomerDiscoveryScreen<T> is: a
// market wiring layer (e.g. CustomerProductDetailScreen for Food) extracts
// plain values + callbacks from its own model (FoodOfferModel, ProductModel,
// ...) into a [ProductDetailConfig], and owns anything model-specific that
// this screen has no business knowing about — live Mercure subscriptions,
// favorites, navigation targets, translated strings. This file never imports
// a market model or a market's translation keys, so it has zero knowledge of
// what a "food offer" or "cosmetic product" is.
//
// All user-facing text is capped with maxLines/overflow (titles, business
// names, addresses, descriptions) so long values truncate instead of
// wrapping the layout or overflowing on small/landscape screens.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:design_system/design_system.dart';
import 'package:models/models.dart';
import 'package:i18n/i18n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Localized copy [ProductDetailScreen] needs, bundled so this file makes no
/// `.tr` calls itself and has no dependency on any single market's
/// translation-key class. Each market wiring builds one of these from its
/// own strings file (e.g. food's `ProductDetailStrings`).
class ProductDetailLabels {
  final String location;
  final String moreInfo;
  final String getDirections;
  final String mapUnavailable;
  final String tapViewMap;
  final String addressNotAvailable;
  final String businessRating;
  final String noDescription;
  final String weightBasedLabel;
  final String pickUp;
  final String pickupWindow;
  final String from;
  final String until;
  final String today;
  final String tomorrow;
  final String reserve;
  final String offerEnded;
  final String kgAvailableSuffix;

  final String Function(int qty) stockLeft;
  final String Function(String minKg) pricePerKgHint;
  final String Function(int pct) savePct;
  final String Function(String orig, String cur) origValueItem;
  final String Function(String orig, String cur) origValueKg;
  final String Function(int weekday) weekdayShort;
  final String Function(int month) monthShort;

  const ProductDetailLabels({
    required this.location,
    required this.moreInfo,
    required this.getDirections,
    required this.mapUnavailable,
    required this.tapViewMap,
    required this.addressNotAvailable,
    required this.businessRating,
    required this.noDescription,
    required this.weightBasedLabel,
    required this.pickUp,
    required this.pickupWindow,
    required this.from,
    required this.until,
    required this.today,
    required this.tomorrow,
    required this.reserve,
    required this.offerEnded,
    required this.kgAvailableSuffix,
    required this.stockLeft,
    required this.pricePerKgHint,
    required this.savePct,
    required this.origValueItem,
    required this.origValueKg,
    required this.weekdayShort,
    required this.monthShort,
  });
}

/// Everything [ProductDetailScreen] needs to render one item. A market wires
/// this up once per detail screen (see CustomerProductDetailScreen for the
/// Food wiring) by extracting values from its own model — the generic screen
/// never touches the model itself.
class ProductDetailConfig {
  // ── Identity ─────────────────────────────────────────────────────────────
  final String title;
  final String? description;
  final List<ImageModel> images;
  final BusinessPartnerModel? businessPartner;

  // ── Category ─────────────────────────────────────────────────────────────
  final String categoryLabel;
  final IconData categoryIcon;
  final String bagLabel;
  final String aboutTitle;

  // ── Pricing & stock ──────────────────────────────────────────────────────
  final bool isWeightBased;
  final double? originalPrice;
  final double? currentPrice;
  final int? quantityAvailable;
  final double? weightAvailableKg;
  final double? minOrderKg;

  // ── Availability window — null hides the pickup-window row entirely ─────
  final DateTime? startTime;
  final DateTime? endTime;

  // ── Distance from the user — null hides the distance row ───────────────
  final double? distanceKm;

  // ── Status / ordering — decision of what onReserve does (navigate,
  // show a "business closed" dialog, ...) belongs entirely to the caller.
  final bool isOfferActive;
  final VoidCallback onReserve;

  /// Secondary "add to cart" action shown beside the primary reserve/buy
  /// button — null keeps today's single-button layout unchanged (e.g. for a
  /// market that hasn't wired up a cart yet).
  final VoidCallback? onAddToCart;

  // ── Rating — null (or businessPartner.rating <= 0) hides the row ────────
  final VoidCallback? onRatingTap;

  // ── Slots owned by the market wiring ────────────────────────────────────
  // favoriteButton is null for markets with no favorites feature yet (e.g.
  // Cosmetic) — the floating button row simply omits it instead of showing
  // an empty placeholder.
  final Widget? favoriteButton;
  final VoidCallback onShare;
  final VoidCallback onBack;

  final ProductDetailLabels labels;

  const ProductDetailConfig({
    required this.title,
    this.description,
    required this.images,
    required this.businessPartner,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.bagLabel,
    required this.aboutTitle,
    required this.isWeightBased,
    this.originalPrice,
    this.currentPrice,
    this.quantityAvailable,
    this.weightAvailableKg,
    this.minOrderKg,
    this.startTime,
    this.endTime,
    this.distanceKm,
    required this.isOfferActive,
    required this.onReserve,
    this.onAddToCart,
    this.onRatingTap,
    required this.favoriteButton,
    required this.onShare,
    required this.onBack,
    required this.labels,
  });
}

class ProductDetailScreen extends StatefulWidget {
  final ProductDetailConfig config;

  const ProductDetailScreen({super.key, required this.config});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Purely local UI state (hero collapse-on-scroll) — unrelated to whatever
  // live data the market wiring feeds through `widget.config`.
  final _collapsed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final expandedHeroHeight = (MediaQuery.of(context).size.height * 0.38)
        .clamp(180.0, 310.0);

    return ValueListenableBuilder<bool>(
      valueListenable: _collapsed,
      builder: (context, isCollapsed, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isCollapsed
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (n) {
              _collapsed.value = n.metrics.pixels > (expandedHeroHeight - 80.0);
              return false;
            },
            child: Scaffold(
              backgroundColor: AppColors.white,
              extendBodyBehindAppBar: true,
              body: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      _HeroSliver(
                        config: config,
                        isCollapsed: isCollapsed,
                        expandedHeight: expandedHeroHeight,
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoSection(config: config),
                            const _Divider(),
                            if (config.businessPartner?.fullAddress !=
                                null) ...[
                              _LocationSection(
                                bp: config.businessPartner!,
                                labels: config.labels,
                              ),
                              const _Divider(),
                            ],
                            _AboutSection(config: config),
                            const _Divider(),
                            _SavingsSection(config: config),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _FloatingButtons(config: config),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomBar(config: config),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Hero — expandable image with badges + business/product title ───────────

class _HeroSliver extends StatelessWidget {
  final ProductDetailConfig config;
  final bool isCollapsed;
  final double expandedHeight;

  const _HeroSliver({
    required this.config,
    required this.isCollapsed,
    required this.expandedHeight,
  });

  _StockBadge? _resolveStockBadge() {
    if (config.isWeightBased) {
      final kg = config.weightAvailableKg;
      if (kg == null || kg <= 0) return null;
      return _StockBadge(
        label:
            '${CurrencyFormatter.localizeDigits(kg.toStringAsFixed(1))} '
            '${config.labels.kgAvailableSuffix}',
        bg: const Color(0xFFFFF3CD),
        fg: const Color(0xFF856404),
      );
    }
    final qty = config.quantityAvailable ?? 0;
    if (qty <= 0) return null;
    if (qty == 1) {
      return _StockBadge(
        label: config.labels.stockLeft(1),
        bg: const Color(0xFFFEE2E2),
        fg: AppColors.errorDark,
      );
    }
    if (qty <= 3) {
      return _StockBadge(
        label: config.labels.stockLeft(qty),
        bg: const Color(0xFFFFF3CD),
        fg: const Color(0xFF856404),
      );
    }
    return _StockBadge(
      label: config.labels.stockLeft(qty),
      bg: AppColors.successLight,
      fg: AppColors.successDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = config.businessPartner;
    final stockBadge = _resolveStockBadge();

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: isCollapsed ? AppColors.white : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: isCollapsed ? AppColors.textPrimary : AppColors.white,
      automaticallyImplyLeading: false,
      title: Text(
        config.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCollapsed ? AppColors.textPrimary : AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 19,
          shadows: isCollapsed
              ? null
              : const [Shadow(blurRadius: 8, color: Colors.black54)],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image
            config.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: config.images.first.url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: AppColors.primaryLight),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.primaryLight),
                  )
                : Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),

            // Bottom gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.30, 1.0],
                  colors: [Colors.transparent, Color(0xDD000000)],
                ),
              ),
            ),

            // Stock + category badges on image
            if (stockBadge != null)
              Positioned(
                left: 16,
                bottom: 96,
                child: Row(
                  children: [
                    _ImageBadge(
                      label: stockBadge.label,
                      bgColor: stockBadge.bg,
                      textColor: stockBadge.fg,
                    ),
                    const SizedBox(width: 8),
                    _ImageBadge(
                      label: config.bagLabel,
                      bgColor: Colors.white.withValues(alpha: 0.22),
                      textColor: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),

            // Business logo + business name + product title
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials(bp?.businessName ?? config.title),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Business name — capped so a long name can't push
                        // the product title off-screen or overflow.
                        Text(
                          bp?.businessName ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            shadows: [
                              Shadow(blurRadius: 12, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Product title — same weight/size
                        Text(
                          config.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            shadows: [
                              Shadow(blurRadius: 12, color: Colors.black54),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s\-]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _StockBadge {
  final String label;
  final Color bg;
  final Color fg;
  const _StockBadge({required this.label, required this.bg, required this.fg});
}

// ── Small badge stuck on the hero image ──────────────────────────────────────

class _ImageBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  const _ImageBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Floating back + share + favourite buttons ────────────────────────────────

class _FloatingButtons extends StatelessWidget {
  final ProductDetailConfig config;
  const _FloatingButtons({required this.config});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    final safeLeft = MediaQuery.of(
      context,
    ).padding.left.clamp(12.0, double.infinity);
    final safeRight = MediaQuery.of(
      context,
    ).padding.right.clamp(12.0, double.infinity);
    return Positioned(
      top: top,
      left: safeLeft,
      right: safeRight,
      child: Row(
        children: [
          ProductDetailCircleButton(
            onTap: config.onBack,
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const Spacer(),
          ProductDetailCircleButton(
            onTap: config.onShare,
            child: const Icon(Icons.ios_share_rounded, size: 18),
          ),
          if (config.favoriteButton != null) ...[
            const SizedBox(width: 8),
            config.favoriteButton!,
          ],
        ],
      ),
    );
  }
}

/// Small white circular button used for back / share / favorite actions on
/// top of the hero image. Public so market wiring layers can build their own
/// favorite button (which needs custom reactive icon/color logic) with the
/// exact same look instead of duplicating the shadow/circle styling.
class ProductDetailCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ProductDetailCircleButton({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.textPrimary),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ── Info rows: category, rating, distance, pickup time, weight ──────────────

class _InfoSection extends StatelessWidget {
  final ProductDetailConfig config;
  const _InfoSection({required this.config});

  @override
  Widget build(BuildContext context) {
    final bp = config.businessPartner;
    final infoL = MediaQuery.of(
      context,
    ).padding.left.clamp(20.0, double.infinity);
    final infoR = MediaQuery.of(
      context,
    ).padding.right.clamp(20.0, double.infinity);
    return Padding(
      padding: EdgeInsets.fromLTRB(infoL, 22, infoR, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category row
          _InfoRow(
            icon: config.categoryIcon,
            iconBg: AppColors.primaryLight,
            iconColor: AppColors.primary,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    config.bagLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _InlineBadge(label: config.categoryLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rating — tappable only when the caller supplied a target.
          // Always shown when a business is present so the reviews entry
          // point isn't hidden just because averageRating is still 0.
          if (bp != null) ...[
            GestureDetector(
              onTap: config.onRatingTap,
              child: _InfoRow(
                icon: Icons.star_rounded,
                iconBg: AppColors.accentLight,
                iconColor: AppColors.accent,
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.localizeDigits(
                                bp.rating.toStringAsFixed(1),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '  ${config.labels.businessRating}'
                                  '${bp.reviewCount > 0 ? ' (${CurrencyFormatter.localizeDigits('${bp.reviewCount}')})' : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (config.onRatingTap != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (config.distanceKm != null) ...[
            _InfoRow(
              icon: Icons.near_me_outlined,
              iconBg: AppColors.gray100,
              iconColor: AppColors.textSecondary,
              child: Text(
                HelperMethods.formatDistance(config.distanceKm!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (config.startTime != null && config.endTime != null)
            _PickupWindowRow(
              start: config.startTime!,
              end: config.endTime!,
              labels: config.labels,
            ),

          // Weight info
          if (config.isWeightBased) ...[
            SizedBox(height: config.startTime != null ? 16 : 0),
            _InfoRow(
              icon: Icons.scale_outlined,
              iconBg: AppColors.gray100,
              iconColor: AppColors.textSecondary,
              child: Text(
                config.labels.pricePerKgHint(
                  CurrencyFormatter.localizeDigits(
                    config.minOrderKg?.toStringAsFixed(1) ?? '0.5',
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _InlineBadge extends StatelessWidget {
  final String label;
  final bool outlined;
  const _InlineBadge({required this.label, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: outlined
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: outlined ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }
}

// ── Pickup window row — same-day compact or multi-day card ───────────────────

class _PickupWindowRow extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final ProductDetailLabels labels;
  const _PickupWindowRow({
    required this.start,
    required this.end,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (sameDay) {
      final now = DateTime.now();
      final isToday =
          now.year == start.year &&
          now.month == start.month &&
          now.day == start.day;
      final tom = now.add(const Duration(days: 1));
      final isTomorrow =
          tom.year == start.year &&
          tom.month == start.month &&
          tom.day == start.day;
      final dayLabel = isToday
          ? labels.today
          : isTomorrow
          ? labels.tomorrow
          : '${labels.weekdayShort(start.weekday)} ${start.day} ${labels.monthShort(start.month)}';

      return _InfoRow(
        icon: Icons.schedule_rounded,
        iconBg: AppColors.gray100,
        iconColor: AppColors.textSecondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  labels.pickUp,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _InlineBadge(label: dayLabel, outlined: true)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${HelperMethods.formatTimeOnly(start)} – ${HelperMethods.formatTimeOnly(end)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Multi-day: show a From → Until card
    return _InfoRow(
      icon: Icons.calendar_month_outlined,
      iconBg: AppColors.primaryLight,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.pickupWindow,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _DateTimeCell(label: labels.from, date: start, labels: labels),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                _DateTimeCell(
                  label: labels.until,
                  date: end,
                  labels: labels,
                  alignEnd: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeCell extends StatelessWidget {
  final String label;
  final DateTime date;
  final ProductDetailLabels labels;
  final bool alignEnd;
  const _DateTimeCell({
    required this.label,
    required this.date,
    required this.labels,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${date.day} ${labels.monthShort(date.month)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          HelperMethods.formatTimeOnly(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Location section ─────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final BusinessPartnerModel bp;
  final ProductDetailLabels labels;
  const _LocationSection({required this.bp, required this.labels});

  Future<void> _openMaps({bool directions = false}) async {
    final lat = double.tryParse(bp.latitude) ?? 0.0;
    final lng = double.tryParse(bp.longitude) ?? 0.0;
    final hasCoords = lat != 0.0 || lng != 0.0;

    final parts = <String>[
      if (bp.street.isNotEmpty) bp.street,
      if (bp.zipCode.isNotEmpty) bp.zipCode,
      if (bp.city.isNotEmpty) bp.city,
    ];
    final address = parts.join(', ');

    final Uri uri;
    if (hasCoords) {
      uri = directions
          ? Uri.parse(
              'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
            )
          : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
            );
    } else if (address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      uri = directions
          ? Uri.parse(
              'https://www.google.com/maps/dir/?api=1&destination=$encoded',
            )
          : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$encoded',
            );
    } else {
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (bp.street.isNotEmpty) bp.street,
      if (bp.zipCode.isNotEmpty) bp.zipCode,
      if (bp.city.isNotEmpty) bp.city,
    ];
    final address = parts.join(', ');

    final locL = MediaQuery.of(
      context,
    ).padding.left.clamp(20.0, double.infinity);
    final locR = MediaQuery.of(
      context,
    ).padding.right.clamp(20.0, double.infinity);
    return Padding(
      padding: EdgeInsets.fromLTRB(locL, 20, locR, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.location,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: address.isNotEmpty ? () => _openMaps() : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.isEmpty ? labels.addressNotAvailable : address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      Text(
                        labels.moreInfo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: address.isNotEmpty ? () => _openMaps() : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: (MediaQuery.of(context).size.height * 0.16).clamp(
                  90.0,
                  130.0,
                ),
                width: double.infinity,
                color: AppColors.gray100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 32,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address.isEmpty
                            ? labels.mapUnavailable
                            : labels.tapViewMap,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CustomDynamicButton(
            variant: CustomButtonVariant.outlined,
            fullWidth: true,
            borderRadius: 12,
            icon: Icons.directions_outlined,
            label: labels.getDirections,
            onPressed: address.isNotEmpty
                ? () => _openMaps(directions: true)
                : null,
          ),
        ],
      ),
    );
  }
}

// ── About this product ───────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final ProductDetailConfig config;
  const _AboutSection({required this.config});

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        config.description != null && config.description!.isNotEmpty;

    final aboutL = MediaQuery.of(
      context,
    ).padding.left.clamp(20.0, double.infinity);
    final aboutR = MediaQuery.of(
      context,
    ).padding.right.clamp(20.0, double.infinity);
    return Padding(
      padding: EdgeInsets.fromLTRB(aboutL, 20, aboutR, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.aboutTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (hasDescription)
            Text(
              config.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            )
          else
            Text(
              config.labels.noDescription,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(
                label: config.categoryLabel,
                icon: config.categoryIcon,
              ),
              if (config.isWeightBased)
                _CategoryChip(
                  label: config.labels.weightBasedLabel,
                  icon: Icons.scale_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Savings highlight ────────────────────────────────────────────────────────

class _SavingsSection extends StatelessWidget {
  final ProductDetailConfig config;
  const _SavingsSection({required this.config});

  @override
  Widget build(BuildContext context) {
    final orig = config.originalPrice;
    final cur = config.currentPrice;

    if (orig == null || cur == null || orig <= cur) {
      return const SizedBox.shrink();
    }

    final saved = orig - cur;
    final pct = ((saved / orig) * 100).round();

    final savL = MediaQuery.of(
      context,
    ).padding.left.clamp(20.0, double.infinity);
    final savR = MediaQuery.of(
      context,
    ).padding.right.clamp(20.0, double.infinity);
    return Padding(
      padding: EdgeInsets.fromLTRB(savL, 20, savR, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.successDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.savings_outlined,
                size: 20,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.labels.savePct(pct),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.isWeightBased
                        ? config.labels.origValueKg(
                            CurrencyFormatter.perKg(orig),
                            CurrencyFormatter.perKg(cur),
                          )
                        : config.labels.origValueItem(
                            CurrencyFormatter.format(orig),
                            CurrencyFormatter.format(cur),
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.successDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section divider ───────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 8, color: const Color(0xFFF2F2F0));
  }
}

// ── Sticky bottom bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final ProductDetailConfig config;
  const _BottomBar({required this.config});

  @override
  Widget build(BuildContext context) {
    final orig = config.originalPrice;
    final cur = config.currentPrice;
    final hasDiscount = orig != null && cur != null && orig > cur;

    final priceLabel = config.isWeightBased
        ? (cur != null ? CurrencyFormatter.perKg(cur) : '—')
        : (cur != null ? CurrencyFormatter.format(cur) : '—');
    final origLabel = config.isWeightBased
        ? (orig != null ? CurrencyFormatter.perKg(orig) : '')
        : (orig != null ? CurrencyFormatter.format(orig) : '');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).padding.left.clamp(20.0, double.infinity),
        14,
        MediaQuery.of(context).padding.right.clamp(20.0, double.infinity),
        14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDiscount)
                  Text(
                    origLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textHint,
                    ),
                  ),
                Text(
                  priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (config.onAddToCart != null) ...[
            SizedBox(
              height: 54,
              width: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: config.isOfferActive
                        ? AppColors.primary
                        : AppColors.gray300,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: config.isOfferActive ? config.onAddToCart : null,
                child: Icon(
                  Icons.add_shopping_cart_rounded,
                  size: 22,
                  color: config.isOfferActive
                      ? AppColors.primary
                      : AppColors.gray300,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.isOfferActive
                      ? AppColors.primary
                      : AppColors.gray300,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: config.isOfferActive ? config.onReserve : null,
                child: Text(
                  config.isOfferActive
                      ? config.labels.reserve
                      : config.labels.offerEnded,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
