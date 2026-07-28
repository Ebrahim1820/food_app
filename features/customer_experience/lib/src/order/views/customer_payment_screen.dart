// Food's payment step. Thin wiring layer over the generic PaymentScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/payment_screen.dart):
// this file owns everything Food-specific — FoodOfferModel, delivery-address
// validation via AddressController, resolving userIri, and the exact
// OrderController.placeOrder payload — and hands it all to the generic
// screen via a PaymentScreenConfig. Other markets (Cosmetic, ...) wire up
// their own payment step the same way against the same generic screen, with
// their own model/controller (see CosmeticCheckoutScreen).
import 'package:flutter/material.dart';
import 'package:profile/profile.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:payment/payment.dart';
import 'package:models/models.dart';
import '../../discovery/views/payment_screen.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

export '../../discovery/views/payment_screen.dart'
    show PaymentScreenBinding;

/// Kept as its own name (rather than every call site importing
/// [PaymentScreenBinding] directly) purely so [CustomerPaymentScreen]'s
/// callers don't need to know the generic screen exists.
class CustomerPaymentBinding extends PaymentScreenBinding {}

class CustomerPaymentScreen extends StatelessWidget {
  final FoodOfferModel offer;
  final int quantity;
  final double? weightKg; // non-null for weight-based offers
  final double subtotal;
  final double deliveryFee;
  final double total;

  const CustomerPaymentScreen({
    super.key,
    required this.offer,
    required this.quantity,
    this.weightKg,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  // Business name + quantity, same combined line the old hero subtitle
  // showed — OrderLineItemsCard renders it as the secondary line under the
  // item's own title.
  String get _quantityLabel {
    final qty = weightKg != null
        ? CurrencyFormatter.formatWeight(weightKg!, decimals: 2)
        : CustomerPaymentStrings.quantityLabel(quantity);
    final businessName = offer.businessPartner?.businessName ?? '';
    return businessName.isEmpty ? qty : '$businessName  ·  $qty';
  }

  Future<void> _onConfirm(BuildContext context, PaymentController ctrl) async {
    final orderCtrl = Get.find<OrderController>();
    final addrCtrl = Get.find<AddressController>();
    final isDelivery = addrCtrl.isDelivery.value;
    final address = addrCtrl.selectedAddress.value;

    // Only delivery orders need an address — pickup orders send none at all.
    if (isDelivery && address == null) {
      AppSnackbar.error('', CustomerPaymentStrings.noAddressError);
      return;
    }

    String userIri = orderCtrl.userIri.value;
    if (userIri.isEmpty) {
      final ok = await orderCtrl.fetchUserIri();
      userIri = orderCtrl.userIri.value;
      if (!ok || userIri.isEmpty) {
        AppSnackbar.error(
          ErrorStrings.title,
          CustomerPaymentStrings.accountVerifyError,
        );
        return;
      }
    }

    final partner = offer.businessPartner;
    final partnerIri = partner?.iri ?? '';
    if (partner == null || partnerIri.endsWith('/')) {
      AppSnackbar.error(
        ErrorStrings.title,
        CustomerPaymentStrings.partnerNotFoundError,
      );
      return;
    }

    await orderCtrl.placeOrder(
      businessPartnerIri: partnerIri,
      deliveryAddressIri: isDelivery ? address!.iri : null,
      notes: orderCtrl.notes.value,
      userIri: userIri,
      paymentMethod: ctrl.paymentMethod.value,
      items: [
        {
          'product': offer.iri,
          'quantity': weightKg != null ? 1 : quantity,
          'status': 'pending',
          if (weightKg != null) 'weightKg': weightKg!.toStringAsFixed(2),
          if (weightKg != null) 'weightTotalKg': weightKg!.toStringAsFixed(2),
        },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderCtrl = Get.find<OrderController>();
    return PaymentScreen(
      config: PaymentScreenConfig(
        items: [
          OrderLineItem(
            title: offer.title,
            imageUrl: offer.images.isNotEmpty ? offer.images.first.url : null,
            quantityLabel: _quantityLabel,
            totalPrice: subtotal,
          ),
        ],
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        cashAvailable: offer.businessPartner?.acceptsCashPayment == true,
        isPlacingOrder: orderCtrl.isPlacingOrder,
        onConfirm: _onConfirm,
      ),
    );
  }
}
