import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_offer_controller.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/services/image_service.dart';
import 'package:food_app/services/push_notification_service.dart';
import 'package:food_app/constants/food/shared_customer_and_business_constants/food_offer_strings.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/utils/helper_methods.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class OfferPreviewScreen extends StatefulWidget {
  final FoodOfferModel draft;
  final XFile? localImage;
  final int businessPartnerId;

  const OfferPreviewScreen({
    super.key,
    required this.draft,
    required this.businessPartnerId,
    this.localImage,
  });

  @override
  State<OfferPreviewScreen> createState() => _OfferPreviewScreenState();
}

class _OfferPreviewScreenState extends State<OfferPreviewScreen> {
  bool _publishing = false;

  Future<void> _publish() async {
    setState(() => _publishing = true);
    PushNotificationService.publishingOffer = true;
    try {
      final c = Get.find<BusinessOfferController>();
      final created = await c.submitDraft(
        widget.draft,
        widget.businessPartnerId,
      );

      if (created == null) {
        if (!mounted) return;
        setState(() => _publishing = false);
        AppSnackbar.error(
          ErrorStrings.title,
          c.errorText.value.isNotEmpty
              ? c.errorText.value
              : FoodOfferStrings.previewPublishError,
        );
        return;
      }

      if (widget.localImage != null) {
        try {
          final bytes = await widget.localImage!.readAsBytes();
          await Get.find<ImageService>().uploadImage(
            fileBytes: bytes,
            filename: widget.localImage!.name,
            imageType: 'product',
            partnerIri: '/api/business-partners/${widget.businessPartnerId}',
            productIri: created.iri,
          );
        } catch (_) {
          // Image upload failure is non-fatal — offer is already created
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } finally {
      PushNotificationService.publishingOffer = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.draft;
    final businessName =
        Get.find<BusinessPartnerController>().partner.value?.businessName ?? '';

    final orig = double.tryParse(offer.originalPrice ?? '');
    final cur = offer.isWeightBased
        ? offer.pricePerKg
        : double.tryParse(offer.price ?? '');
    final hasDiscount = orig != null && cur != null && orig > cur;
    final saved = hasDiscount ? orig - cur : 0.0;
    final pct = hasDiscount ? ((saved / orig) * 100).round() : 0;

    final timeRange =
        '${HelperMethods.formatTimeOnly(offer.startTime)} – ${HelperMethods.formatTimeOnly(offer.endTime)}';
    final priceLabel = offer.isWeightBased
        ? (cur != null ? CurrencyFormatter.perKg(cur) : '—')
        : (cur != null ? CurrencyFormatter.format(cur) : '—');
    final origLabel = offer.isWeightBased
        ? (orig != null ? CurrencyFormatter.perKg(orig) : '')
        : (orig != null ? CurrencyFormatter.format(orig) : '');

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero image ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.navy,
                surfaceTintColor: Colors.transparent,
                foregroundColor: AppColors.white,
                automaticallyImplyLeading: false,
                title: Text(
                  offer.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image or placeholder
                      widget.localImage != null
                          ? Image.file(
                              File(widget.localImage!.path),
                              fit: BoxFit.cover,
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
                            stops: [0.3, 1.0],
                            colors: [Colors.transparent, Color(0xDD000000)],
                          ),
                        ),
                      ),

                      // Business name + offer title overlay
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          businessName.isNotEmpty ? businessName : offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            shadows: [
                              Shadow(blurRadius: 12, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),

                      // PREVIEW badge — top right
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PREVIEW',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Offer title ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // ── Category chip ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: _chip(FoodCategories.label(offer.category)),
                    ),

                    const _Divider(),

                    // ── Info rows ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.schedule_rounded,
                            AppColors.gray100,
                            AppColors.textSecondary,
                            'Pick up: $timeRange',
                          ),
                          if (offer.isWeightBased) ...[
                            const SizedBox(height: 14),
                            _infoRow(
                              Icons.scale_outlined,
                              AppColors.gray100,
                              AppColors.textSecondary,
                              offer.minOrderKg != null
                                  ? 'Min order: ${offer.minOrderKg!.toStringAsFixed(1)} kg'
                                  : 'Sold by weight (kg)',
                            ),
                          ],
                          if (offer.quantityAvailable != null &&
                              !offer.isWeightBased) ...[
                            const SizedBox(height: 14),
                            _infoRow(
                              Icons.inventory_2_outlined,
                              AppColors.primaryLight,
                              AppColors.primary,
                              '${offer.quantityAvailable} bag(s) available',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const _Divider(),

                    // ── Description ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About this offer',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            offer.description?.isNotEmpty == true
                                ? offer.description!
                                : 'No description provided.',
                            style: TextStyle(
                              fontSize: 14,
                              color: offer.description?.isNotEmpty == true
                                  ? AppColors.textSecondary
                                  : AppColors.textHint,
                              height: 1.6,
                              fontStyle: offer.description?.isNotEmpty == true
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Savings banner ───────────────────────────────────
                    if (hasDiscount) ...[
                      const _Divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
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
                                      'Save $pct% on this order',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.successDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Original value: $origLabel → $priceLabel',
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
                      ),
                    ],

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),

          // ── Back button (floating) ──────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: Get.back,
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
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // ── Bottom action bar ───────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                20,
                14,
                20,
                14 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Price info ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceLabel,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            origLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Row 2: Edit + Publish buttons ───────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              side: const BorderSide(color: AppColors.gray300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _publishing ? null : Get.back,
                            child: Text(
                              FoodOfferStrings.previewEdit,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.successDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _publishing ? null : _publish,
                            icon: _publishing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 20),
                            label: Text(
                              _publishing
                                  ? FoodOfferStrings.previewPublishing
                                  : FoodOfferStrings.previewPublish,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    ),
  );

  Widget _infoRow(IconData icon, Color iconBg, Color iconColor, String label) =>
      Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 8, color: const Color(0xFFF2F2F0));
}
