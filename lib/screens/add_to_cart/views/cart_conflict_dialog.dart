import 'package:flutter/material.dart';
import 'package:food_app/constants/add_to_cart/cart_strings.dart';
import 'package:food_app/controllers/cart_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/confirm_dialog.dart';

/// Gates every [CartController.addItem] call from the UI side. Returns true
/// immediately if [cart] is empty or already belongs to [businessIri] — no
/// dialog shown. Otherwise asks the user to confirm clearing the other
/// business's items first (same behavior as Uber Eats/DoorDash: one cart,
/// one business at a time), clears on confirm, and returns whether it's now
/// safe to add.
Future<bool> confirmCartSwitch(
  BuildContext context,
  CartController cart,
  String businessIri,
) async {
  if (cart.canAddFrom(businessIri)) return true;

  final confirmed = await ConfirmDialog.show(
    context,
    icon: Icons.remove_shopping_cart_rounded,
    title: CartStrings.switchBusinessTitle,
    subtitle: cart.businessName.value,
    body: CartStrings.switchBusinessBody,
    confirmLabel: CartStrings.switchBusinessConfirm,
    cancelLabel: CartStrings.switchBusinessCancel,
    dangerColor: AppColors.warningDark,
    dangerLightColor: AppColors.warningLight,
  );

  if (confirmed != true) return false;
  cart.clear();
  return true;
}
