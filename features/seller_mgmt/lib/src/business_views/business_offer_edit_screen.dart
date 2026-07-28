// lib/screens/business/business_offer_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:auth/auth.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:notification/notification.dart';
import 'package:models/models.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// ---------------------------------------------------------------------------
// Business Offer Edit Screen
//
// Lets a business partner update the details of an existing surplus offer.
// Photos are shown as a horizontal row of thumbnails — tap the "+" card to
// upload a new photo immediately (POST /images with the offer IRI).
// Field changes are sent via PATCH when the user taps "Save changes".
//
// Returns `true` via Get.back() so the caller can refresh its list.
// ---------------------------------------------------------------------------

class BusinessOfferEditScreen extends StatefulWidget {
  const BusinessOfferEditScreen({super.key, required this.offer});
  final FoodOfferModel offer;

  @override
  State<BusinessOfferEditScreen> createState() =>
      _BusinessOfferEditScreenState();
}

class _BusinessOfferEditScreenState extends State<BusinessOfferEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── text controllers ──────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _originalCtrl;
  late final TextEditingController _priceCtrl;

  // ── weight-based controllers ──────────────────────────────────────────────
  late final TextEditingController _pricePerKgCtrl;
  late final TextEditingController _weightKgCtrl;
  late final TextEditingController _minOrderKgCtrl;

  // ── form state ────────────────────────────────────────────────────────────
  late bool _isWeightBased;
  late String _category;
  late int _quantity;
  late DateTime _pickupStart;
  late DateTime _pickupEnd;
  late String _status;

  bool _isSaving = false;
  bool _isDeleting = false;
  String _errorText = '';

  // ── photo state ───────────────────────────────────────────────────────────
  // Full ImageModel list so each thumbnail knows its backend id for deletion.
  late List<ImageModel> _images;
  bool _photoUploading = false;
  bool _photoDeleting = false;

  final _picker = ImagePicker();
  final _imageService = Get.find<ImageService>();
  static const _tag = 'BusinessOfferEditScreen';

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _nameCtrl = TextEditingController(text: o.title);
    _descCtrl = TextEditingController(text: o.description ?? '');
    _originalCtrl = TextEditingController(
      text: CurrencyFormatter.localizeDigits(o.originalPrice ?? ''),
    );
    _priceCtrl = TextEditingController(
      text: CurrencyFormatter.localizeDigits(o.price ?? ''),
    );

    _isWeightBased = o.isWeightBased;
    _pricePerKgCtrl = TextEditingController(
      text: o.pricePerKg != null
          ? CurrencyFormatter.localizeDigits(o.pricePerKg!.toStringAsFixed(2))
          : '',
    );
    _weightKgCtrl = TextEditingController(
      text: o.weightAvailableKg != null
          ? CurrencyFormatter.localizeDigits(
              o.weightAvailableKg!.toStringAsFixed(2),
            )
          : '',
    );
    _minOrderKgCtrl = TextEditingController(
      text: o.minOrderKg != null
          ? CurrencyFormatter.localizeDigits(o.minOrderKg!.toStringAsFixed(2))
          : '',
    );

    // Normalise category so the dropdown always finds its item.
    final normalised = o.category.toLowerCase();
    _category = BusinessOfferController.categories.contains(normalised)
        ? normalised
        : BusinessOfferController.categories.first;

    _quantity = o.quantityTotal ?? 1;
    _pickupStart = o.startTime.toLocal();
    _pickupEnd = o.endTime.toLocal();
    _status = o.status.isNotEmpty ? o.status : 'active';

    // Pre-populate image strip from the existing offer images.
    _images = o.images.toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _originalCtrl.dispose();
    _priceCtrl.dispose();
    _pricePerKgCtrl.dispose();
    _weightKgCtrl.dispose();
    _minOrderKgCtrl.dispose();
    super.dispose();
  }

  // ── computed ──────────────────────────────────────────────────────────────

  int get _discountPercent {
    final orig = CurrencyFormatter.parseLocalizedDouble(_originalCtrl.text);
    final deal = CurrencyFormatter.parseLocalizedDouble(_priceCtrl.text);
    if (orig <= 0 || deal <= 0 || deal >= orig) return 0;
    return ((1 - deal / orig) * 100).round();
  }

  // ── date / time picker ────────────────────────────────────────────────────

  Future<void> _pickWindow() async {
    final result = await PickupWindowPicker.show(
      context,
      initialStart: _pickupStart,
      initialEnd: _pickupEnd,
    );
    if (result == null || !mounted) return;
    setState(() {
      _pickupStart = result.start;
      _pickupEnd = result.end;
    });
  }

  // ── photo upload ──────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto() async {
    final source = await showPhotoSourceSheet(
      context,
      cameraLabel: BusinessOfferEditStrings.imageSourceCamera,
      galleryLabel: BusinessOfferEditStrings.imageSourceGallery,
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
      AppLogger.info(_tag, 'pickImage error: $e');
    }

    if (picked == null) {
      if (source == ImageSource.camera) {
        AppSnackbar.error(
          BusinessOfferEditStrings.snackCameraUnavailableTitle,
          BusinessOfferEditStrings.snackCameraUnavailableBody,
        );
      }
      return;
    }

    setState(() => _photoUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final image = await _imageService.uploadImage(
        fileBytes: bytes,
        filename: picked.name,
        imageType: 'product',
        productIri: widget.offer.iri,
        imgPosition: _images.length,
      );
      if (mounted) setState(() => _images.add(image));
      AppSnackbar.success(
        BusinessOfferEditStrings.snackPhotoAddedTitle,
        BusinessOfferEditStrings.snackPhotoAddedBody,
      );
    } catch (e) {
      AppLogger.info(_tag, 'Photo upload error: $e');
      AppSnackbar.error(BusinessOfferEditStrings.snackUploadFailedTitle, e.toString());
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  Future<void> _deletePhoto(ImageModel image) async {
    setState(() => _photoDeleting = true);
    try {
      await _imageService.deleteImage(image.id);
      if (mounted) setState(() => _images.remove(image));
    } catch (e) {
      AppLogger.info(_tag, 'Photo delete error: $e');
      if (mounted) {
        AppSnackbar.error(BusinessOfferEditStrings.snackErrorTitle, e.toString());
      }
    } finally {
      if (mounted) setState(() => _photoDeleting = false);
    }
  }

  // ── save / delete ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_pickupEnd.isAfter(_pickupStart)) {
      setState(
        () => _errorText = BusinessOfferEditStrings.validatorPickupOrder,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = '';
    });

    final Map<String, dynamic> body;
    if (_isWeightBased) {
      final pricePerKg = CurrencyFormatter.parseLocalizedDouble(
        _pricePerKgCtrl.text,
      );
      final weightKg = CurrencyFormatter.parseLocalizedDouble(
        _weightKgCtrl.text,
      );
      final minKgText = _minOrderKgCtrl.text.trim();
      body = {
        'title': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        'category': _category,
        'pricePerKg': pricePerKg.toStringAsFixed(2),
        'weightTotalKg': weightKg.toStringAsFixed(2),
        'weightAvailableKg': weightKg.toStringAsFixed(2),
        if (minKgText.isNotEmpty)
          'minOrderKg': CurrencyFormatter.parseLocalizedDouble(
            minKgText,
          ).toStringAsFixed(2),
        'startTime': _pickupStart.toUtc().toIso8601String(),
        'endTime': _pickupEnd.toUtc().toIso8601String(),
        'status': _status,
      };
    } else {
      final orig = CurrencyFormatter.parseLocalizedDouble(_originalCtrl.text);
      final price = CurrencyFormatter.parseLocalizedDouble(_priceCtrl.text);
      body = {
        'title': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        'category': _category,
        'originalPrice': orig.toStringAsFixed(2),
        'salePrice': price.toStringAsFixed(2),
        'quantityTotal': _quantity,
        'quantityAvailable': _quantity,
        'startTime': _pickupStart.toUtc().toIso8601String(),
        'endTime': _pickupEnd.toUtc().toIso8601String(),
        'status': _status,
      };
    }

    final ctrl = Get.find<BusinessOfferController>();
    final ok = await ctrl.updateOffer(widget.offer.id, body);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      _snack(BusinessOfferEditStrings.snackOfferUpdated);
      // Close both the edit screen and the detail screen to land directly
      // on the offer list, where the updated status is already reflected.
      Get.close(2);
    } else {
      setState(
        () => _errorText = ctrl.updateErrorText.isNotEmpty
            ? ctrl.updateErrorText
            : BusinessOfferEditStrings.snackCouldNotSave,
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.delete_forever_rounded,
      title: BusinessOfferDialogStrings.deleteTitle,
      subtitle: BusinessOfferDialogStrings.offerSubtitle(widget.offer.title),
      body: BusinessOfferDialogStrings.deleteBody,
      confirmLabel: BusinessOfferDialogStrings.deleteConfirmLabel,
      cancelLabel: BusinessOfferDialogStrings.deleteCancelLabel,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final ctrl = Get.find<BusinessOfferController>();
    final ok = await ctrl.deleteOffer(widget.offer.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (ok) {
      _snack(BusinessOfferEditStrings.snackOfferDeleted);
      Get.back(result: true);
    } else {
      _snack(
        ctrl.updateErrorText.isNotEmpty
            ? ctrl.updateErrorText
            : BusinessOfferEditStrings.snackCouldNotDelete,
        isError: true,
      );
    }
  }

  void _snack(String msg, {bool isError = false}) => isError
      ? AppSnackbar.error(BusinessOfferEditStrings.snackErrorTitle, msg)
      : AppSnackbar.success(BusinessOfferEditStrings.snackDoneTitle, msg);

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ProductFormScaffold(
      formKey: _formKey,
      appBarTitle: BusinessOfferEditStrings.appBarTitle,
      appBarActions: [
        _isDeleting
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                onPressed: _confirmDelete,
                tooltip: BusinessOfferEditStrings.deleteTooltip,
              ),
      ],
      photoSlot: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(BusinessOfferEditStrings.sectionPhotos),
          PersistedPhotoGallery(
            images: _images,
            isUploading: _photoUploading,
            isDeleting: _photoDeleting,
            onAddTap: (_photoUploading || _photoDeleting)
                ? null
                : _pickAndUploadPhoto,
            onDelete: (_photoUploading || _photoDeleting)
                ? null
                : _deletePhoto,
            addPhotoLabel: BusinessOfferEditStrings.addPhotoButton,
          ),
        ],
      ),
      bottomBar: Obx(() {
        final isVerified = Get.find<AuthController>().isEmailVerified.value;
        return PrimaryActionFab(
          label: BusinessOfferEditStrings.saveButton,
          icon: Icons.check_rounded,
          isLoading: _isSaving,
          onPressed: (_isSaving || _isDeleting || !isVerified)
              ? null
              : _save,
        );
      }),
      fields: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferEditStrings.sectionStatus),
            _StatusChips(
              current: _status,
              onChanged: (s) => setState(() => _status = s),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferEditStrings.sectionName),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: productFormInputDecoration(
                BusinessOfferEditStrings.nameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? BusinessOfferEditStrings.validatorNameRequired
                  : null,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferEditStrings.sectionDescription),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: productFormInputDecoration(
                BusinessOfferEditStrings.descriptionHint,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferEditStrings.sectionCategory),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: productFormInputDecoration(null),
              items: BusinessOfferController.categories
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(_prettyCategory(cat)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferEditStrings.sectionPricing),
            _isWeightBased ? _weightFields() : _pieceFields(),
          ],
        ),
        if (!_isWeightBased) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormFieldLabel(BusinessOfferEditStrings.sectionQuantity),
              QuantityStepper(
                quantity: _quantity,
                onIncrease: () => setState(() => _quantity++),
                onDecrease: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                onChanged: (v) => setState(() => _quantity = v),
              ),
            ],
          ),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(BusinessOfferEditStrings.sectionPickup),
            PickupWindowField(
              start: _pickupStart,
              end: _pickupEnd,
              onTap: _pickWindow,
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
                const SizedBox(height: 4),
              ],
              if (_errorText.isNotEmpty)
                Text(
                  _errorText,
                  style: const TextStyle(
                    color: AppColors.errorDark,
                    fontSize: 13,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _pieceFields() {
    final affixes = currencyAffixes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceFieldPair(
          labelBuilder: (l) => FormFieldCaption(l),
          leftLabel: BusinessOfferEditStrings.originalPriceLabel,
          leftController: _originalCtrl,
          leftHint: '15.00',
          leftOnChanged: (_) => setState(() {}),
          leftValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessOfferEditStrings.validatorRequired,
            invalidMsg: BusinessOfferEditStrings.validatorInvalidAmount,
          ),
          rightLabel: BusinessOfferEditStrings.dealPriceLabel,
          rightController: _priceCtrl,
          rightHint: '5.00',
          rightOnChanged: (_) => setState(() {}),
          rightValidator: (v) => validateBelowOriginal(
            v,
            originalText: _originalCtrl.text,
            requiredMsg: BusinessOfferEditStrings.validatorRequired,
            invalidMsg: BusinessOfferEditStrings.validatorInvalidAmount,
            belowOriginalMsg: BusinessOfferEditStrings.validatorBelowOriginal,
          ),
          prefix: affixes.prefix,
          suffix: affixes.suffix,
        ),
        if (_discountPercent > 0) ...[
          const SizedBox(height: 10),
          _DiscountBadge(percent: _discountPercent),
        ],
      ],
    );
  }

  Widget _weightFields() {
    final priceAffixes = currencyAffixes();
    final weightAff = weightAffixes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceFieldPair(
          labelBuilder: (l) => FormFieldCaption(l),
          leftLabel: BusinessOfferCreateStrings.labelPricePerKg,
          leftController: _pricePerKgCtrl,
          leftHint: '3.50',
          leftValidator: (v) => validateBelowOriginal(
            v,
            originalText: _originalCtrl.text,
            requiredMsg: BusinessOfferEditStrings.validatorRequired,
            invalidMsg: BusinessOfferEditStrings.validatorInvalidAmount,
            belowOriginalMsg: BusinessOfferEditStrings.validatorBelowOriginal,
          ),
          rightLabel: BusinessOfferCreateStrings.labelOrigPricePerKg,
          rightController: _originalCtrl,
          rightHint: '6.00',
          prefix: priceAffixes.prefix,
          suffix: priceAffixes.suffix,
        ),
        const SizedBox(height: 14),
        PriceFieldPair(
          labelBuilder: (l) => FormFieldCaption(l),
          leftLabel: BusinessOfferCreateStrings.labelWeightAvailable,
          leftController: _weightKgCtrl,
          leftHint: '5.0',
          leftValidator: (v) => validatePositiveAmount(
            v,
            requiredMsg: BusinessOfferEditStrings.validatorRequired,
            invalidMsg: BusinessOfferEditStrings.validatorInvalidAmount,
          ),
          rightLabel: BusinessOfferCreateStrings.labelMinOrder,
          rightController: _minOrderKgCtrl,
          rightHint: '0.5',
          prefix: weightAff.prefix,
          suffix: weightAff.suffix,
        ),
      ],
    );
  }

  String _prettyCategory(String c) => c
      .replaceAll('_', ' ')
      .replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());
}

// ---------------------------------------------------------------------------
// Status chips
// ---------------------------------------------------------------------------
class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  // Non-static getter so .tr is re-evaluated on every build when locale changes.
  List<(String, String, Color, Color)> get _statuses => [
    (
      'active',
      OfferStatusLabels.active,
      AppColors.primary,
      AppColors.successLight,
    ),
    (
      'inactive',
      OfferStatusLabels.inactive,
      AppColors.warningDark,
      const Color(0xFFFFF7ED),
    ),
    (
      'cancelled',
      OfferStatusLabels.cancelled,
      AppColors.error,
      AppColors.errorLight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _statuses.map((s) {
        final (value, label, fg, _) = s;
        final selected = current == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? fg : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? fg : AppColors.gray200,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: fg.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Savings badge
// ---------------------------------------------------------------------------
class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.successDark.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 14,
            color: AppColors.successDark,
          ),
          const SizedBox(width: 5),
          Text(
            BusinessOfferEditStrings.discountBadge(percent),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.successDark,
            ),
          ),
        ],
      ),
    );
  }
}
