import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:get/get.dart';

import 'package:auth/auth.dart';
import 'package:notification/notification.dart';
import 'package:design_system/design_system.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:i18n/i18n.dart';
import 'package:seller_mgmt/seller_mgmt.dart';

/// "Publish a Cosmetics listing" screen — backed by [BusinessProductController]
/// (registered with `market: 'cosmetic'`), the market-agnostic counterpart to
/// `CreateFoodOfferScreen`. Built from the shared widgets under
/// `business_product_form/` so this form stays visually and behaviorally in
/// sync with Food's create screen instead of drifting as a separate copy.
class CreateProductScreen extends StatelessWidget {
  const CreateProductScreen({super.key});

  BusinessProductController get _c =>
      Get.find<BusinessProductController>(tag: Market.cosmetic.value);

  Future<void> _pickImage(BuildContext context) async {
    final source = await showPhotoSourceSheet(
      context,
      cameraLabel: ProductCreatePhotoStrings.camera,
      galleryLabel: ProductCreatePhotoStrings.gallery,
    );
    if (source == null) return;
    await _c.pickImage(source);
  }

  Future<void> _submit(BuildContext context) async {
    final c = _c;
    final created = await c.submit();
    if (!context.mounted) return;

    if (created == null) {
      AppSnackbar.error(
        BusinessProductStrings.snackErrorTitle,
        c.errorText.value.isNotEmpty
            ? c.errorText.value
            : BusinessProductStrings.snackCouldNotSave,
      );
      return;
    }

    // The photo is picked up-front but the product didn't have an id to
    // attach it to until now — upload it right after creation, mirroring
    // how Food's OfferPreviewScreen uploads its pending photo post-create.
    final pending = c.pendingImage.value;
    if (pending != null) {
      try {
        final bytes = await pending.readAsBytes();
        await Get.find<ImageService>().uploadImage(
          fileBytes: bytes,
          filename: pending.name,
          imageType: 'product',
          productIri: created.iri,
        );
      } catch (_) {
        // Image upload failure is non-fatal — the product is already created.
      }
    }

    AppSnackbar.success(
      BusinessProductStrings.snackSuccessTitle,
      BusinessProductStrings.snackPublished,
    );
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return ProductFormScaffold(
      formKey: c.formKey,
      appBarTitle: BusinessProductStrings.createAppBarTitle,
      photoSlot: Obx(
        () => SinglePendingPhotoPicker(
          pendingImage: c.pendingImage.value,
          onTap: () => _pickImage(context),
          addPhotoLabel: BusinessProductStrings.addPhoto,
        ),
      ),
      bottomBar: Obx(() {
        final isVerified = Get.find<AuthController>().isEmailVerified.value;
        final isSaving = c.isSaving.value;
        return PrimaryActionFab(
          label: BusinessProductStrings.publishButton,
          icon: Icons.visibility_outlined,
          isLoading: isSaving,
          onPressed: (isSaving || !isVerified)
              ? null
              : () => _submit(context),
        );
      }),
      fields: [
        FormFieldLabel(BusinessProductStrings.labelItemName),
        TextFormField(
          controller: c.nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: productFormInputDecoration(
            BusinessProductStrings.nameHint,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? BusinessProductStrings.validatorNameRequired
              : null,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessProductStrings.labelDescription),
            TextFormField(
              controller: c.descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: productFormInputDecoration(
                BusinessProductStrings.descriptionHint,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessProductStrings.labelCategory),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: c.category.value,
                decoration: productFormInputDecoration(null),
                items: cosmeticCategories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          CosmeticStrings.categoryLabel(cat),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                validator: (_) => c.category.value == null
                    ? BusinessProductStrings.validatorCategoryRequired
                    : null,
                onChanged: (v) {
                  if (v != null) c.setCategory(v);
                },
              ),
            ),
          ],
        ),
        Obx(
          () => WeightModeToggle(
            isWeightBased: c.isWeightBased.value,
            onChanged: (v) => c.isWeightBased.value = v,
            titleLabel: BusinessProductStrings.labelSellByWeight,
            weightHint: BusinessProductStrings.hintWeightExample,
            pieceHint: BusinessProductStrings.hintPortionExample,
          ),
        ),
        Obx(
          () => c.isWeightBased.value
              ? _WeightFields(c: c)
              : _PieceFields(c: c),
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
}

class _PieceFields extends StatelessWidget {
  const _PieceFields({required this.c});
  final BusinessProductController c;

  @override
  Widget build(BuildContext context) {
    final affixes = currencyAffixes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceFieldPair(
          labelBuilder: (l) => FormFieldLabel(l),
          leftLabel: BusinessProductStrings.labelOriginalPrice,
          leftController: c.originalCtrl,
          leftHint: '15.00',
          leftValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessProductStrings.validatorRequired,
            invalidMsg: BusinessProductStrings.validatorInvalidAmount,
          ),
          rightLabel: BusinessProductStrings.labelDealPrice,
          rightController: c.priceCtrl,
          rightHint: '5.00',
          rightValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessProductStrings.validatorRequired,
            invalidMsg: BusinessProductStrings.validatorInvalidAmount,
          ),
          prefix: affixes.prefix,
          suffix: affixes.suffix,
        ),
        const SizedBox(height: 16),
        FormFieldLabel(BusinessProductStrings.labelQuantity),
        Obx(
          () => QuantityStepper(
            quantity: c.quantity.value,
            onIncrease: c.increaseQty,
            onDecrease: c.quantity.value > 1 ? c.decreaseQty : null,
            onChanged: (v) => c.quantity.value = v,
            accentColor: AppColors.successDark,
          ),
        ),
      ],
    );
  }
}

class _WeightFields extends StatelessWidget {
  const _WeightFields({required this.c});
  final BusinessProductController c;

  @override
  Widget build(BuildContext context) {
    final priceAffixes = currencyAffixes();
    final weightAff = weightAffixes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceFieldPair(
          labelBuilder: (l) => FormFieldLabel(l),
          leftLabel: BusinessProductStrings.labelPricePerKg,
          leftController: c.pricePerKgCtrl,
          leftHint: '3.50',
          leftValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessProductStrings.validatorRequired,
            invalidMsg: BusinessProductStrings.validatorInvalidAmount,
          ),
          rightLabel: BusinessProductStrings.labelOrigPricePerKg,
          rightController: c.originalCtrl,
          rightHint: '6.00',
          prefix: priceAffixes.prefix,
          suffix: priceAffixes.suffix,
        ),
        const SizedBox(height: 16),
        PriceFieldPair(
          labelBuilder: (l) => FormFieldLabel(l),
          leftLabel: BusinessProductStrings.labelWeightAvailable,
          leftController: c.weightKgCtrl,
          leftHint: '5.0',
          leftValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessProductStrings.validatorRequired,
            invalidMsg: BusinessProductStrings.validatorInvalidAmount,
          ),
          rightLabel: BusinessProductStrings.labelMinOrder,
          rightController: c.minOrderKgCtrl,
          rightHint: '0.5',
          prefix: weightAff.prefix,
          suffix: weightAff.suffix,
        ),
      ],
    );
  }
}

/// Small local strings holder for the two photo-source sheet labels —
/// mirrors the `abstract class ...Strings` pattern used everywhere else.
abstract class ProductCreatePhotoStrings {
  static String get camera => 'productCreate_photoCamera'.tr;
  static String get gallery => 'productCreate_photoGallery'.tr;
}
