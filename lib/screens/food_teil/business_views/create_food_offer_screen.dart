// lib/screens/business/create_food_offer_screen.dart
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_offer_controller.dart';
import 'package:food_app/screens/food_teil/business_views/offer_preview_screen.dart';
import 'package:food_app/services/user_service.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/screens/shared_customer_business_screens/business_product_form/pickup_window_picker.dart';
import 'package:food_app/screens/food_teil/business_views/primary_action_fab.dart';
import 'package:food_app/screens/shared_customer_business_screens/business_product_form/product_form_field_label.dart';
import 'package:food_app/screens/shared_customer_business_screens/business_product_form/product_form_scaffold.dart';
import 'package:food_app/screens/shared_customer_business_screens/business_product_form/product_photo_picker.dart';
import 'package:food_app/screens/shared_customer_business_screens/business_product_form/quantity_stepper.dart';
import 'package:food_app/screens/shared_customer_business_screens/business_product_form/weight_or_piece_price_fields.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/widgets/email_verification_banner.dart';

class CreateFoodOfferScreen extends StatefulWidget {
  final int businessPartnerId;
  const CreateFoodOfferScreen({super.key, required this.businessPartnerId});

  @override
  State<CreateFoodOfferScreen> createState() => _CreateFoodOfferScreenState();
}

class _CreateFoodOfferScreenState extends State<CreateFoodOfferScreen> {
  final BusinessOfferController c = Get.find<BusinessOfferController>();
  final _picker = ImagePicker();
  XFile? _pendingImage;

  @override
  void dispose() {
    // Clear the singleton controller's form state when the user leaves,
    // so the next open always starts with a blank form.
    c.resetForm();
    super.dispose();
  }

  // --- date/time picker --------------------------------------------------
  Future<void> _pickWindow(BuildContext context) async {
    final result = await PickupWindowPicker.show(
      context,
      initialStart: c.pickupStart.value,
      initialEnd: c.pickupEnd.value,
    );
    if (result == null) return;
    c.setPickup(isStart: true, dt: result.start);
    c.setPickup(isStart: false, dt: result.end);
  }

  // --- image picker ------------------------------------------------------
  Future<void> _pickImage() async {
    final source = await showPhotoSourceSheet(
      context,
      cameraLabel: 'Take a photo',
      galleryLabel: 'Choose from gallery',
      removeLabel: _pendingImage != null ? 'Remove photo' : null,
      onRemove: _pendingImage != null
          ? () => setState(() => _pendingImage = null)
          : null,
    );
    if (source == null) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
    } catch (e) {
      if (mounted && source == ImageSource.camera) {
        _snack(
          'Camera unavailable. Try choosing from gallery.',
          isError: true,
        );
      }
      return;
    }
    if (picked == null) return;
    setState(() => _pendingImage = picked);
  }

  // --- preview & publish -------------------------------------------------
  Future<void> _showPreview(BuildContext context) async {
    final draft = c.buildDraft();
    if (draft == null) {
      _snack(
        c.errorText.value.isNotEmpty
            ? c.errorText.value
            : BusinessOfferCreateStrings.snackCouldNotSave,
        isError: true,
      );
      return;
    }

    final published = await Get.to<bool>(
      () => OfferPreviewScreen(
        draft: draft,
        localImage: _pendingImage,
        businessPartnerId: widget.businessPartnerId,
      ),
    );

    if (published == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (isError) {
      AppSnackbar.error(BusinessOfferCreateStrings.snackErrorTitle, msg);
    } else {
      AppSnackbar.success(BusinessOfferCreateStrings.snackSuccessTitle, msg);
    }
  }

  // --- build -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return ProductFormScaffold(
      formKey: c.formKey,
      appBarTitle: BusinessOfferCreateStrings.appBarTitle,
      photoSlot: SinglePendingPhotoPicker(
        pendingImage: _pendingImage,
        onTap: _pickImage,
        addPhotoLabel: BusinessOfferCreateStrings.addPhoto,
      ),
      bottomBar: Obx(() {
        final isVerified = Get.find<AuthController>().isEmailVerified.value;
        final isSaving = c.isSaving.value;
        return PrimaryActionFab(
          label: BusinessOfferCreateStrings.publishButton,
          icon: Icons.visibility_outlined,
          isLoading: isSaving,
          onPressed: (isSaving || !isVerified)
              ? null
              : () => _showPreview(context),
        );
      }),
      fields: [
        FormFieldLabel(BusinessOfferCreateStrings.labelItemName),
        TextFormField(
          controller: c.nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: productFormInputDecoration(
            BusinessOfferCreateStrings.nameHint,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? BusinessOfferCreateStrings.validatorNameRequired
              : null,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferCreateStrings.labelDescription),
            TextFormField(
              controller: c.descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: productFormInputDecoration(
                BusinessOfferCreateStrings.descriptionHint,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferCreateStrings.labelCategory),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: c.category.value,
                decoration: productFormInputDecoration(null),
                items: BusinessOfferController.categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(_prettyCategory(cat)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => c.setCategory(v ?? c.category.value),
              ),
            ),
          ],
        ),
        Obx(
          () => WeightModeToggle(
            isWeightBased: c.isWeightBased.value,
            onChanged: (v) => c.isWeightBased.value = v,
            titleLabel: BusinessOfferCreateStrings.labelSellByWeight,
            weightHint: BusinessOfferCreateStrings.hintWeightExample,
            pieceHint: BusinessOfferCreateStrings.hintPortionExample,
          ),
        ),
        Obx(
          () => c.isWeightBased.value
              ? _WeightFields(c: c)
              : _PieceFields(c: c),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferCreateStrings.labelPickupWindow),
            Obx(
              () => PickupWindowField(
                start: c.pickupStart.value,
                end: c.pickupEnd.value,
                onTap: () => _pickWindow(context),
              ),
            ),
          ],
        ),
        Obx(() {
          final isVerified = Get.find<AuthController>().isEmailVerified.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isVerified) ...[
                EmailVerificationBannerWidget(
                  email: Get.find<AuthController>().email,
                  onResend: () =>
                      Get.find<UserService>().resendVerificationEmail(
                        Get.find<AuthController>().email,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              if (c.errorText.value.isNotEmpty)
                Text(
                  c.errorText.value,
                  style: const TextStyle(color: AppColors.errorDark),
                ),
            ],
          );
        }),
      ],
    );
  }

  String _prettyCategory(String c) => c
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _PieceFields extends StatelessWidget {
  const _PieceFields({required this.c});
  final BusinessOfferController c;

  @override
  Widget build(BuildContext context) {
    final affixes = currencyAffixes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceFieldPair(
          labelBuilder: (l) => FormFieldLabel(l),
          leftLabel: BusinessOfferCreateStrings.labelOriginalPrice,
          leftController: c.originalCtrl,
          leftHint: '15.00',
          leftValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessOfferCreateStrings.validatorRequired,
            invalidMsg: BusinessOfferCreateStrings.validatorInvalidAmount,
          ),
          rightLabel: BusinessOfferCreateStrings.labelDealPrice,
          rightController: c.priceCtrl,
          rightHint: '5.00',
          rightValidator: (v) => validateBelowOriginal(
            v,
            originalText: c.originalCtrl.text,
            requiredMsg: BusinessOfferCreateStrings.validatorRequired,
            invalidMsg: BusinessOfferCreateStrings.validatorInvalidAmount,
            belowOriginalMsg: BusinessOfferCreateStrings.validatorBelowOriginal,
          ),
          prefix: affixes.prefix,
          suffix: affixes.suffix,
        ),
        const SizedBox(height: 16),
        FormFieldLabel(BusinessOfferCreateStrings.labelQuantity),
        Obx(
          () => QuantityStepper(
            quantity: c.quantity.value,
            onIncrease: c.increaseQty,
            onDecrease: c.quantity.value > 1 ? c.decreaseQty : null,
            onChanged: (v) => c.quantity.value = v,
          ),
        ),
      ],
    );
  }
}

class _WeightFields extends StatelessWidget {
  const _WeightFields({required this.c});
  final BusinessOfferController c;

  @override
  Widget build(BuildContext context) {
    final priceAffixes = currencyAffixes();
    final weightAff = weightAffixes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceFieldPair(
          labelBuilder: (l) => FormFieldLabel(l),
          leftLabel: BusinessOfferCreateStrings.labelPricePerKg,
          leftController: c.pricePerKgCtrl,
          leftHint: '3.50',
          leftValidator: (v) => validateBelowOriginal(
            v,
            originalText: c.originalCtrl.text,
            requiredMsg: BusinessOfferCreateStrings.validatorRequired,
            invalidMsg: BusinessOfferCreateStrings.validatorInvalidAmount,
            belowOriginalMsg: BusinessOfferCreateStrings.validatorBelowOriginal,
          ),
          rightLabel: BusinessOfferCreateStrings.labelOrigPricePerKg,
          rightController: c.originalCtrl,
          rightHint: '6.00',
          prefix: priceAffixes.prefix,
          suffix: priceAffixes.suffix,
        ),
        const SizedBox(height: 16),
        PriceFieldPair(
          labelBuilder: (l) => FormFieldLabel(l),
          leftLabel: BusinessOfferCreateStrings.labelWeightAvailable,
          leftController: c.weightKgCtrl,
          leftHint: '5.0',
          leftValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessOfferCreateStrings.validatorRequired,
            invalidMsg: BusinessOfferCreateStrings.validatorInvalidAmount,
          ),
          rightLabel: BusinessOfferCreateStrings.labelMinOrder,
          rightController: c.minOrderKgCtrl,
          rightHint: '0.5',
          prefix: weightAff.prefix,
          suffix: weightAff.suffix,
        ),
      ],
    );
  }
}
