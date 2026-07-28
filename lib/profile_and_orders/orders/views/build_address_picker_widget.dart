import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/profile/controllers/address_controller.dart';
import 'package:food_app/models/address_model.dart';
import 'package:food_app/profile_and_orders/profile/views/customer_addresses_screen.dart'
    show CustomerAddressesScreen, customerAddressLabelOptions;
import 'package:food_app/profile_and_orders/orders/constants/customer_checkout_strings.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/profile_and_orders/profile/views/address_form_sheet.dart';
import 'package:get/get.dart';

/// Sentinel value for the "Add a new address" dropdown entry — distinct from
/// any real address id so it can't collide with one.
const _addNewAddressValue = '__add_new_address__';

class BuildAddressPickerWidget extends StatelessWidget {
  const BuildAddressPickerWidget({super.key});

  /// Opens the same add/edit bottom sheet used on the address management
  /// screen, right on top of checkout, so adding or fixing an address
  /// doesn't take the user out of their order. When [existing] is null this
  /// adds a new address and auto-selects whichever one is new when the sheet
  /// closes; when editing, the current selection just refreshes in place.
  Future<void> _openAddressSheet(
    BuildContext context,
    AddressController addressController, {
    required AddressModel? existing,
  }) async {
    final beforeIds = addressController.addresses.map((a) => a.id).toSet();
    await showAddressFormSheet(
      context,
      addressController,
      existing: existing,
      labelOptions: customerAddressLabelOptions(),
      addTitle: CustomerProfileStrings.addNewAddress,
      editTitle: CustomerProfileStrings.editAddress,
      saveLabel: CustomerProfileStrings.saveChanges,
    );
    if (existing != null) return;
    final added = addressController.addresses.firstWhereOrNull(
      (a) => !beforeIds.contains(a.id),
    );
    if (added != null) {
      addressController.selectedAddress.value = added;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AddressController addressController = Get.find();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              CustomerCheckoutStrings.deliveryAddressLabel,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Obx(() {
              final selected = addressController.selectedAddress.value;
              if (selected == null) return const SizedBox.shrink();
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openAddressSheet(
                  context,
                  addressController,
                  existing: selected,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        CustomerCheckoutStrings.editAddressLink,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (addressController.isLoading.value) {
            return const CircularProgressIndicator();
          }

          if (addressController.addresses.isEmpty) {
            return Text(CustomerCheckoutStrings.noSavedAddresses);
          }

          return DropdownButtonFormField<String>(
            initialValue: addressController.selectedAddress.value?.id,
            hint: Text(CustomerCheckoutStrings.selectAddressHint),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: [
              ...addressController.addresses.map((address) {
                return DropdownMenuItem(
                  value: address.id,
                  child: Text('${address.street}, ${address.city}'),
                );
              }),
              DropdownMenuItem(
                value: _addNewAddressValue,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_location_alt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      CustomerCheckoutStrings.addNewAddressOption,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value == _addNewAddressValue) {
                _openAddressSheet(context, addressController, existing: null);
                return;
              }
              final selected = addressController.addresses.firstWhereOrNull(
                (a) => a.id == value,
              );
              if (selected != null) {
                addressController.selectedAddress.value = selected;
              }
            },
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY TOGGLE — pickup vs. delivery. Shared across markets since it's
// pure AddressController state; a business's actual delivery fee is applied
// by whichever screen reads AddressController.isDelivery, not by this widget.
// ─────────────────────────────────────────────────────────────────────────────

class DeliveryToggle extends StatelessWidget {
  const DeliveryToggle({super.key, required this.addressController});

  final AddressController addressController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDelivery = addressController.isDelivery.value;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            isDelivery
                ? CustomerCheckoutStrings.deliverInsteadLabel
                : CustomerCheckoutStrings.pickupLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            isDelivery
                ? CustomerCheckoutStrings.deliverInsteadOnSubtitle
                : CustomerCheckoutStrings.deliverInsteadOffSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          value: isDelivery,
          onChanged: addressController.setDelivery,
          activeThumbColor: AppColors.primary,
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO-ADDRESS BANNER — shown when delivery is selected but the user has no
// saved address yet.
// ─────────────────────────────────────────────────────────────────────────────

class NoAddressBanner extends StatelessWidget {
  const NoAddressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.errorDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CustomerCheckoutStrings.noAddressTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.errorDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CustomerCheckoutStrings.noAddressBody,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.errorDark.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => Get.to(() => const CustomerAddressesScreen()),
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: Text(
                CustomerCheckoutStrings.addAddressButton,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorDark,
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
