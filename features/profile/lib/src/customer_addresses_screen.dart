import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'address_controller.dart';
import 'package:models/models.dart';
import 'customer_profile_strings.dart';
import 'address_form_sheet.dart';
import 'package:get/get.dart';

class CustomerAddressesScreen extends StatelessWidget {
  const CustomerAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddressController>();

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
          CustomerProfileStrings.myAddresses,
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
          // Always read reactive values first so GetX registers all dependencies
          // regardless of which branch is taken below.
          final snapshot = ctrl.addresses.toList();
          final isLoading = ctrl.isLoading.value;
          final selectedId = ctrl.selectedAddress.value?.id;

          if (isLoading && snapshot.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.isEmpty) {
            return _EmptyAddresses(
              onAdd: () => _showFormSheet(context, ctrl, existing: null),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: snapshot.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final address = snapshot[i];
              final isSelected = selectedId == address.id;
              return _AddressCard(
                address: address,
                isSelected: isSelected,
                onTap: () => ctrl.selectAddress(address),
                onEdit: () => _showFormSheet(context, ctrl, existing: address),
                onDelete: () => _confirmDelete(context, ctrl, address),
                onSetDefault: address.isPrimary
                    ? null
                    : () => ctrl.setDefault(address.id),
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
          CustomerProfileStrings.addNewAddress,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showFormSheet(context, ctrl, existing: null),
      ),
    );
  }

  void _showFormSheet(
    BuildContext context,
    AddressController ctrl, {
    required AddressModel? existing,
  }) {
    showAddressFormSheet(
      context,
      ctrl,
      existing: existing,
      labelOptions: customerAddressLabelOptions(),
      addTitle: CustomerProfileStrings.addNewAddress,
      editTitle: CustomerProfileStrings.editAddress,
      saveLabel: CustomerProfileStrings.saveChanges,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AddressController ctrl,
    AddressModel address,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      title: CustomerProfileStrings.deleteAddressTitle,
      body: CustomerProfileStrings.deleteAddressBody,
      confirmLabel: CustomerProfileStrings.deleteAddressConfirm,
      cancelLabel: CustomerProfileStrings.deleteAddressCancel,
    );
    if (confirmed == true) ctrl.deleteAddress(address.id);
  }
}

// ── Label helpers ─────────────────────────────────────────────────────────────

List<({String value, String label, IconData icon})>
customerAddressLabelOptions() => [
  (
    value: 'home',
    label: CustomerProfileStrings.labelHome,
    icon: Icons.home_rounded,
  ),
  (
    value: 'work',
    label: CustomerProfileStrings.labelWork,
    icon: Icons.work_rounded,
  ),
  (
    value: 'other',
    label: CustomerProfileStrings.labelOther,
    icon: Icons.location_on_rounded,
  ),
];

IconData _labelIcon(String label) {
  switch (label) {
    case 'home':
      return Icons.home_rounded;
    case 'work':
      return Icons.work_rounded;
    default:
      return Icons.location_on_rounded;
  }
}

String _labelText(String label) {
  switch (label) {
    case 'home':
      return CustomerProfileStrings.labelHome;
    case 'work':
      return CustomerProfileStrings.labelWork;
    default:
      return CustomerProfileStrings.labelOther;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAddresses({required this.onAdd});

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
                Icons.location_on_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              CustomerProfileStrings.noAddresses,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CustomerProfileStrings.noAddressesBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            CustomDynamicButton(
              borderRadius: 14,
              icon: Icons.add_rounded,
              label: CustomerProfileStrings.addNewAddress,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Address card ──────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final label = address.labelOrDefault;

    // Each interactive zone has its own handler — no outer GestureDetector
    // wrapping everything, which would swallow taps meant for the radio/button.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
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
          // ── Header row: radio + label chip + badges + edit/delete ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 6, 0),
            child: Row(
              children: [
                // Radio button — dedicated tap zone for setting default
                GestureDetector(
                  onTap: onSetDefault,
                  behavior: HitTestBehavior.opaque,
                  child: Tooltip(
                    message: address.isPrimary
                        ? CustomerProfileStrings.defaultBadge
                        : CustomerProfileStrings.setAsDefault,
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
                // Label chip — filled when selected for delivery
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _labelIcon(label),
                        size: 14,
                        color: isSelected ? AppColors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _labelText(label),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primary,
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
                      CustomerProfileStrings.defaultBadge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
                if (isSelected && !address.isPrimary) ...[
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
                      CustomerProfileStrings.selected,
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
          // ── Address body — tap here to select for delivery ──
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                8,
                14,
                onSetDefault != null ? 4 : 14,
              ),
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
                ],
              ),
            ),
          ),
          // ── Set as Default button — non-primary cards only ──
          if (onSetDefault != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: CustomDynamicButton(
                variant: CustomButtonVariant.outlined,
                fullWidth: true,
                borderRadius: 10,
                icon: Icons.radio_button_unchecked_rounded,
                label: CustomerProfileStrings.setAsDefault,
                onPressed: onSetDefault,
              ),
            ),
        ],
      ),
    );
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
