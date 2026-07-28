// lib/screens/business/business_offer_detail_screen.dart
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_offer_controller.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/screens/food_teil/business_views/business_offer_edit_screen.dart';
import 'package:food_app/services/mercure_service.dart';
import 'package:food_app/strings/business_offer_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/utils/app_logger.dart';
import 'package:food_app/utils/currency_formatter.dart';
import 'package:food_app/widgets/common/confirm_dialog.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Business Offer Detail Screen
//
// Read-only view of a single surplus offer:
//   • AppBar identical in style to the edit screen (back + "Edit" action)
//   • Framed image slider below the AppBar (rounded card, swipeable)
//   • Offer details: status, category, title, prices, description,
//     pickup window, quantity
//   • "Edit this offer" primary button at the bottom
//
// Returns true via Get.back() when an edit or delete occurred so the menu
// list can refresh.
// ---------------------------------------------------------------------------

class BusinessOfferDetailScreen extends StatefulWidget {
  const BusinessOfferDetailScreen({super.key, required this.offer});

  final FoodOfferModel offer;

  @override
  State<BusinessOfferDetailScreen> createState() =>
      _BusinessOfferDetailScreenState();
}

class _BusinessOfferDetailScreenState extends State<BusinessOfferDetailScreen> {
  static const _tag = 'BusinessOfferDetailScreen';
  static const _mercure = MercureService();

  final _pageCtrl = PageController();
  int _currentPage = 0;

  late FoodOfferModel _offer;
  StreamSubscription? _stockSub;

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;

    // Public topic, no auth — same one CustomerProductDetailScreen
    // subscribes to, so a business partner watching their own offer sees
    // quantity/weight/status update live as orders come in, instead of a
    // static snapshot that only refreshes on the next manual visit. See
    // [[project_mercure_realtime]] for why this mirrors that screen.
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
  }

  @override
  void dispose() {
    _stockSub?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEdit() async {
    final updated = await Get.to<bool>(
      () => BusinessOfferEditScreen(offer: _offer),
    );
    if (updated == true && mounted) Get.back(result: true);
  }

  Future<void> _confirmCancel() async {
    // Already cancelled — nothing to do.
    if (_offer.status == 'cancelled') {
      AppSnackbar.success(
        BusinessOfferDetailStrings.snackAlreadyCancelledTitle,
        BusinessOfferDetailStrings.snackAlreadyCancelledBody,
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.block_rounded,
      title: BusinessOfferDialogStrings.cancelTitle,
      subtitle: BusinessOfferDialogStrings.offerSubtitle(_offer.title),
      body: BusinessOfferDialogStrings.cancelBody,
      confirmLabel: BusinessOfferDialogStrings.cancelConfirmLabel,
      cancelLabel: BusinessOfferDialogStrings.cancelCancelLabel,
      dangerColor: AppColors.warningDark,
      dangerLightColor: AppColors.warningLight,
    );
    if (confirmed != true || !mounted) return;

    final ctrl = Get.find<BusinessOfferController>();
    final ok = await ctrl.updateOffer(_offer.id, {'status': 'cancelled'});
    if (!mounted) return;

    if (ok) {
      // Navigate first, then show the snackbar — if we snackbar before
      // Get.back() the overlay is disposed with the route and never appears.
      Get.back(result: true);
      AppSnackbar.success(
        BusinessOfferDetailStrings.snackOfferCancelledTitle,
        BusinessOfferDetailStrings.snackOfferCancelledBody,
      );
    } else {
      AppSnackbar.error(
        BusinessOfferDetailStrings.snackErrorTitle,
        ctrl.updateErrorText.isNotEmpty
            ? ctrl.updateErrorText
            : BusinessOfferDetailStrings.snackCouldNotCancel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── AppBar — same style as the edit screen ──────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          BusinessOfferDetailStrings.appBarTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          CustomDynamicButton(
            label: BusinessOfferDetailStrings.editAction,
            onPressed: _openEdit,
            variant: CustomButtonVariant.text,
            icon: Icons.edit_outlined,
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            // ── Image frame ─────────────────────────────────────────────────
            _ImageFrame(
              images: offer.images.map((e) => e.url).toList(),
              pageCtrl: _pageCtrl,
              currentPage: _currentPage,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),

            const SizedBox(height: 20),

            // ── Status + category ────────────────────────────────────────────
            Row(
              children: [
                _StatusBadge(status: offer.status),
                const SizedBox(width: 8),
                _CategoryChip(category: offer.category),
              ],
            ),

            const SizedBox(height: 12),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              offer.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 14),

            // ── Price row ────────────────────────────────────────────────────
            _PriceRow(offer: offer),

            // ── Description ──────────────────────────────────────────────────
            if (offer.description != null && offer.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                offer.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.65,
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 16),

            // ── Pickup window ────────────────────────────────────────────────
            _InfoRow(
              icon: Icons.schedule_rounded,
              iconColor: AppColors.infoDark,
              label: BusinessOfferDetailStrings.pickupWindowLabel,
              value: _formatWindow(offer.startTime, offer.endTime),
            ),

            const SizedBox(height: 14),

            // ── Quantity / Weight ─────────────────────────────────────────────
            _InfoRow(
              icon: offer.isWeightBased
                  ? Icons.scale_outlined
                  : Icons.inventory_2_outlined,
              iconColor: AppColors.primary,
              label: BusinessOfferDetailStrings.quantityLabel,
              value: offer.isWeightBased
                  ? CurrencyFormatter.formatWeight(offer.weightAvailableKg ?? 0)
                  : (offer.quantityAvailable ?? 0) > 0
                  ? BusinessOfferDetailStrings.quantityRemaining(
                      offer.quantityAvailable ?? 0,
                      offer.quantityTotal ?? 0,
                    )
                  : OfferStatusLabels.soldOut,
            ),

            const SizedBox(height: 32),

            // ── Edit button ──────────────────────────────────────────────────
            CustomDynamicButton(
              label: BusinessOfferDetailStrings.editButton,
              onPressed: _openEdit,
              icon: Icons.edit_outlined,
              accentColor: AppColors.primary,
              fullWidth: true,
              borderRadius: 14,
            ),

            const SizedBox(height: 12),

            // ── Cancel offer button ──────────────────────────────────────────
            // Only shown when the offer is not already cancelled.
            if (offer.status != 'cancelled')
              CustomDynamicButton(
                label: BusinessOfferDetailStrings.cancelButton,
                onPressed: _confirmCancel,
                variant: CustomButtonVariant.outlined,
                accentColor: AppColors.warningDark,
                icon: Icons.cancel_outlined,
                fullWidth: true,
                borderRadius: 14,
              ),
          ],
        ),
      ),
    );
  }

  String _formatWindow(DateTime s, DateTime e) {
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    final day = DateFormat('MMM d');
    final time = DateFormat('HH:mm');
    return sameDay
        ? '${day.format(s)}, ${time.format(s)} – ${time.format(e)}'
        : '${day.format(s)} ${time.format(s)} → ${day.format(e)} ${time.format(e)}';
  }
}

// ---------------------------------------------------------------------------
// Framed image slider — white card with rounded corners, fixed height.
// Swipe left/right to browse multiple images; shows dots + page counter.
// Falls back to a gradient placeholder when the offer has no images.
// ---------------------------------------------------------------------------
class _ImageFrame extends StatelessWidget {
  const _ImageFrame({
    required this.images,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<String> images;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  static const _height = 240.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: images.isEmpty
            ? _Placeholder()
            : Stack(
                fit: StackFit.expand,
                children: [
                  // Swipeable images
                  PageView.builder(
                    controller: pageCtrl,
                    onPageChanged: onPageChanged,
                    itemCount: images.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const SizedBox.shrink(),
                      errorWidget: (_, _, _) => _Placeholder(),
                    ),
                  ),

                  // Page counter badge — top right
                  if (images.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentPage + 1} / ${images.length}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Dot indicator — bottom centre
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: currentPage == i ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: currentPage == i
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// Gradient placeholder shown when no image is available
class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(
      child: Icon(
        Icons.restaurant_menu_rounded,
        color: Colors.white30,
        size: 64,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      'active' => (
        OfferStatusLabels.active,
        AppColors.successDark,
        AppColors.successLight,
      ),
      'inactive' => (
        OfferStatusLabels.inactive,
        AppColors.warningDark,
        const Color(0xFFFFF7ED),
      ),
      'cancelled' => (
        OfferStatusLabels.cancelled,
        AppColors.error,
        AppColors.errorLight,
      ),
      'sold_out' => (
        OfferStatusLabels.soldOut,
        AppColors.gray500,
        AppColors.gray100,
      ),
      'expired' => (
        OfferStatusLabels.expired,
        AppColors.errorDark,
        AppColors.errorLight,
      ),
      _ => (status, AppColors.gray500, AppColors.gray100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip
// ---------------------------------------------------------------------------
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final label = category
        .replaceAll('_', ' ')
        .replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.gray600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price row: deal price + original (strikethrough) + "Save X%" badge
// ---------------------------------------------------------------------------
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.offer});
  final FoodOfferModel offer;

  // Renders amount with a smaller currency unit label.
  // In Farsi: splits "۱۲٬۵۰۰ تومان" so تومان is visually smaller.
  // In English: renders "€12.50" as a single string (€ symbol stays same size).
  Widget _priceText(double amount) {
    const numStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: AppColors.successDark,
    );
    if (!CurrencyFormatter.isFarsi) {
      return Text(CurrencyFormatter.format(amount), style: numStyle);
    }
    final formatted = CurrencyFormatter.format(amount);
    final number = formatted.replaceAll(' ${CurrencyFormatter.faToman}', '');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: number, style: numStyle),
          TextSpan(
            text: ' ${CurrencyFormatter.faToman}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.successDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (offer.isWeightBased) {
      final priceKg = offer.pricePerKg ?? 0;
      final origKg = double.tryParse(offer.originalPrice ?? '') ?? 0;
      final pct = (origKg > 0 && priceKg < origKg)
          ? ((1 - priceKg / origKg) * 100).round()
          : 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Line 1: deal price/kg
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (CurrencyFormatter.isFarsi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, right: 4),
                  child: Text(
                    CurrencyFormatter.faPerKgLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              _priceText(priceKg),
              if (!CurrencyFormatter.isFarsi)
                const Padding(
                  padding: EdgeInsets.only(bottom: 3, left: 3),
                  child: Text(
                    '/kg',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          // Line 2: original price + discount badge
          if (origKg > priceKg || pct > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (origKg > priceKg)
                    Text(
                      CurrencyFormatter.perKg(origKg),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray400,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.gray400,
                      ),
                    ),
                  if (pct > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        BusinessOfferDetailStrings.savePct(pct),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.successDark,
                        ),
                      ),
                    ),
                  ],
                ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line 1: deal price
        _priceText(deal),
        // Line 2: original price + discount badge
        if (orig > deal || pct > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (orig > deal)
                  Text(
                    CurrencyFormatter.format(orig),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray400,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.gray400,
                    ),
                  ),
                if (pct > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      BusinessOfferDetailStrings.savePct(pct),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Labelled icon row (pickup window / quantity)
// ---------------------------------------------------------------------------
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
