import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_address_controller.dart';
import 'package:food_app/models/address_model.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/address_widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessAddressesScreen extends StatelessWidget {
  const BusinessAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BusinessAddressController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          BusinessAddressStrings.appBarTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          // Always access both reactive values first so GetX registers them as
          // dependencies regardless of which branch is taken below.
          final snapshot = ctrl.addresses.toList();
          final isLoading = ctrl.isLoading.value;

          if (isLoading && snapshot.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.isEmpty) {
            return _EmptyLocations(
              onAdd: () => _showFormSheet(context, ctrl, existing: null),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: snapshot.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final address = snapshot[i];
              return _LocationCard(
                address: address,
                onEdit: () => _showFormSheet(context, ctrl, existing: address),
                onDelete: () => _confirmDelete(
                  context,
                  ctrl,
                  address,
                  isLast: snapshot.length == 1,
                ),
                onSetPrimary: address.isPrimary
                    ? null
                    : () => ctrl.setPrimary(address.id),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          BusinessAddressStrings.addNewLocation,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showFormSheet(context, ctrl, existing: null),
      ),
    );
  }

  void _showFormSheet(
    BuildContext context,
    BusinessAddressController ctrl, {
    required AddressModel? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationFormSheet(ctrl: ctrl, existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BusinessAddressController ctrl,
    AddressModel address, {
    required bool isLast,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(BusinessAddressStrings.deleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(BusinessAddressStrings.deleteBody),
            if (isLast) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.warningDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        BusinessAddressStrings.deleteLastWarning,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.warningDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          CustomDynamicButton(
            label: BusinessAddressStrings.deleteCancel,
            onPressed: () => Navigator.pop(ctx, false),
            variant: CustomButtonVariant.text,
            accentColor: AppColors.textSecondary,
          ),
          CustomDynamicButton(
            label: BusinessAddressStrings.deleteConfirm,
            onPressed: () => Navigator.pop(ctx, true),
            variant: CustomButtonVariant.text,
            accentColor: AppColors.error,
          ),
        ],
      ),
    );
    if (confirmed == true) ctrl.deleteAddress(address.id);
  }
}

// ── Label helpers ─────────────────────────────────────────────────────────────

List<({String value, String label, IconData icon})> _bizLabelOptions() => [
  (
    value: 'main',
    label: BusinessAddressStrings.labelMain,
    icon: Icons.store_rounded,
  ),
  (
    value: 'branch',
    label: BusinessAddressStrings.labelBranch,
    icon: Icons.storefront_rounded,
  ),
  (
    value: 'warehouse',
    label: BusinessAddressStrings.labelWarehouse,
    icon: Icons.warehouse_rounded,
  ),
  (
    value: 'other',
    label: BusinessAddressStrings.labelOther,
    icon: Icons.location_on_rounded,
  ),
];

IconData _bizLabelIcon(String label) {
  switch (label) {
    case 'main':
      return Icons.store_rounded;
    case 'branch':
      return Icons.storefront_rounded;
    case 'warehouse':
      return Icons.warehouse_rounded;
    default:
      return Icons.location_on_rounded;
  }
}

String _bizLabelText(String label) {
  switch (label) {
    case 'main':
      return BusinessAddressStrings.labelMain;
    case 'branch':
      return BusinessAddressStrings.labelBranch;
    case 'warehouse':
      return BusinessAddressStrings.labelWarehouse;
    default:
      return BusinessAddressStrings.labelOther;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyLocations extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLocations({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              BusinessAddressStrings.noLocations,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              BusinessAddressStrings.noLocationsBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            CustomDynamicButton(
              label: BusinessAddressStrings.addNewLocation,
              onPressed: onAdd,
              icon: Icons.add_rounded,
              accentColor: AppColors.primary,
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location card ─────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetPrimary;

  const _LocationCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final label = address.labelOrDefault;
    final hasCoords = address.latitude != null && address.longitude != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isPrimary ? AppColors.primary : AppColors.divider,
          width: address.isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: radio + chips + actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 6, 0),
            child: Row(
              children: [
                // Radio button — tappable on non-primary cards
                GestureDetector(
                  onTap: onSetPrimary,
                  behavior: HitTestBehavior.opaque,
                  child: Tooltip(
                    message: address.isPrimary
                        ? BusinessAddressStrings.primaryBadge
                        : BusinessAddressStrings.setPrimary,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        address.isPrimary
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 24,
                        color: address.isPrimary
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                // Label chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _bizLabelIcon(label),
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _bizLabelText(label),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (address.isPrimary) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      BusinessAddressStrings.primaryBadge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                _CardIconBtn(
                  icon: Icons.edit_outlined,
                  color: AppColors.textSecondary,
                  onTap: onEdit,
                ),
                _CardIconBtn(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
          // ── Address body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.street,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (address.street2 != null && address.street2!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      address.street2!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${address.city}, ${address.country}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (address.postalCode.isNotEmpty)
                  Text(
                    address.postalCode,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                // ── Map link ──
                if (hasCoords) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        _openMap(address.latitude!, address.longitude!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'bizAddr_viewOnMap'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // ── Set as Primary button (non-primary cards only) ──
                if (onSetPrimary != null) ...[
                  const SizedBox(height: 10),
                  CustomDynamicButton(
                    label: BusinessAddressStrings.setPrimary,
                    onPressed: onSetPrimary,
                    variant: CustomButtonVariant.outlined,
                    accentColor: AppColors.primary,
                    icon: Icons.radio_button_unchecked_rounded,
                    fullWidth: true,
                    borderRadius: 10,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openMap(String lat, String lng) {
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _CardIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CardIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ── Location form sheet ───────────────────────────────────────────────────────

class _LocationFormSheet extends StatefulWidget {
  final BusinessAddressController ctrl;
  final AddressModel? existing;

  const _LocationFormSheet({required this.ctrl, required this.existing});

  @override
  State<_LocationFormSheet> createState() => _LocationFormSheetState();
}

class _LocationFormSheetState extends State<_LocationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _label;
  late final TextEditingController _street;
  late final TextEditingController _street2;
  late final TextEditingController _city;
  late final TextEditingController _postal;
  late final TextEditingController _country;
  late final TextEditingController _countryCode;
  late final TextEditingController _state;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = a?.labelOrDefault ?? 'main';
    _street = TextEditingController(text: a?.street ?? '');
    _street2 = TextEditingController(text: a?.street2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _country = TextEditingController(text: a?.country ?? '');
    _countryCode = TextEditingController(text: a?.countryCode ?? '');
    _state = TextEditingController(text: a?.state ?? '');
    _lat = TextEditingController(text: a?.latitude ?? '');
    _lng = TextEditingController(text: a?.longitude ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _street,
      _street2,
      _city,
      _postal,
      _country,
      _countryCode,
      _state,
      _lat,
      _lng,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'label': _label,
      'street': _street.text.trim(),
      if (_street2.text.trim().isNotEmpty) 'street2': _street2.text.trim(),
      'city': _city.text.trim(),
      'postalCode': _postal.text.trim(),
      'country': _country.text.trim(),
      'countryCode': _countryCode.text.trim(),
      if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
      if (_lat.text.trim().isNotEmpty) 'latitude': _lat.text.trim(),
      if (_lng.text.trim().isNotEmpty) 'longitude': _lng.text.trim(),
    };

    if (widget.existing == null) {
      await widget.ctrl.createAddress(fields);
    } else {
      await widget.ctrl.updateAddress(widget.existing!.id, fields);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared drag handle
              const SheetHandle(),
              const SizedBox(height: 16),
              Text(
                isEdit
                    ? BusinessAddressStrings.editLocation
                    : BusinessAddressStrings.addNewLocation,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              // Shared label selector (different options from customer)
              AddressLabelSelector(
                options: _bizLabelOptions(),
                selected: _label,
                onChanged: (v) => setState(() => _label = v),
              ),
              const SizedBox(height: 16),
              // Shared form field widget throughout
              AddressFormField(
                controller: _street,
                label: BusinessAddressStrings.streetLabel,
                required: true,
              ),
              const SizedBox(height: 10),
              AddressFormField(
                controller: _street2,
                label: BusinessAddressStrings.street2Label,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AddressFormField(
                      controller: _city,
                      label: BusinessAddressStrings.cityLabel,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AddressFormField(
                      controller: _postal,
                      label: BusinessAddressStrings.postalLabel,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AddressFormField(
                      controller: _country,
                      label: BusinessAddressStrings.countryLabel,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AddressFormField(
                      controller: _countryCode,
                      label: BusinessAddressStrings.countryCodeLabel,
                      required: true,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AddressFormField(
                controller: _state,
                label: BusinessAddressStrings.stateLabel,
              ),
              const SizedBox(height: 16),
              // ── Coordinates (optional) ──
              const Divider(color: AppColors.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AddressFormField(
                      controller: _lat,
                      label: BusinessAddressStrings.latLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AddressFormField(
                      controller: _lng,
                      label: BusinessAddressStrings.lngLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomDynamicButton(
                label: BusinessAddressStrings.saveButton,
                onPressed: _submit,
                isLoading: _saving,
                accentColor: AppColors.primary,
                fullWidth: true,
                borderRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
