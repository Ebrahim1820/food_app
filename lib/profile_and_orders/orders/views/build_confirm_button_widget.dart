import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/profile/controllers/address_controller.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/profile_and_orders/orders/views/customer_payment_screen.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_payment_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class BuildConfirmButtonWidget extends StatelessWidget {
  BuildConfirmButtonWidget({
    super.key,
    required this.total,
    required this.subtotal,
    required this.deliveryFee,
    required this.offer,
    required this.quantity,
    this.weightKg,
  });

  final FoodOfferModel offer;
  final double total;
  final double subtotal;
  final double deliveryFee;
  final RxInt quantity;
  final RxDouble? weightKg;

  final AddressController addressController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isVerified = Get.find<AuthController>().isEmailVerified.value;
      final address = addressController.selectedAddress.value;
      final hasRequiredAddress =
          !addressController.isDelivery.value || address != null;

      // Was previously missing entirely — the button stayed enabled and
      // just sent whatever `quantity`/`weightKg` happened to hold, even a
      // manually-typed value above what's actually in stock.
      final isQuantityValid = offer.isWeightBased
          ? (weightKg == null ||
                (weightKg!.value > 0 &&
                    weightKg!.value <= (offer.weightAvailableKg ?? 0) &&
                    weightKg!.value >= (offer.minOrderKg ?? 0)))
          : (quantity.value >= 1 &&
                quantity.value <= (offer.quantityAvailable ?? 0));

      final canProceed =
          hasRequiredAddress &&
          isVerified &&
          !offer.isSoldOut &&
          isQuantityValid;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: canProceed
                  ? () => Get.to(
                      () => CustomerPaymentScreen(
                        offer: offer,
                        quantity: quantity.value,
                        weightKg: weightKg?.value,
                        subtotal: subtotal,
                        deliveryFee: deliveryFee,
                        total: total,
                      ),
                      binding: CustomerPaymentBinding(),
                      transition: Transition.cupertino,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.4,
                ),
                foregroundColor: AppColors.white,
                disabledForegroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    CustomerPaymentStrings.proceedToPaymentButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
