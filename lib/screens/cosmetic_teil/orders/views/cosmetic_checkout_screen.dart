import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/constants/cosmetic/cosmetic_strings.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_controller.dart';
import 'package:food_app/controllers/prodcuct_controllers/product_order_controller.dart';
import 'package:food_app/models/product_models/product_model.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_payment_strings.dart';
import 'package:food_app/profile_and_orders/orders/controllers/payment_controller.dart';
import 'package:food_app/profile_and_orders/orders/views/build_address_picker_widget.dart';
import 'package:food_app/profile_and_orders/orders/views/build_price_breakdown_widget.dart';
import 'package:food_app/profile_and_orders/orders/views/order_line_items_card.dart';
import 'package:food_app/profile_and_orders/profile/controllers/address_controller.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/payment_screen.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';

/// Fulfillment step for a single [ProductModel] order — the Cosmetic-flavored
/// consumer entry point onto the generic product-order pipeline. Deliberately
/// simpler than Food's `OrderCheckoutScreen` (one product per order, no
/// cart): this proves the end-to-end order flow works, further checkout
/// polish (cart) is a follow-up once Cosmetics has more than one product's
/// worth of demand to justify it. Pickup/delivery + address picking reuse
/// exactly the same [AddressController]/[DeliveryToggle]/
/// [BuildAddressPickerWidget] Food's checkout does — fulfillment isn't a
/// market-specific concept, only whether a given seller offers delivery is
/// (via [ProductModel.businessPartner]'s shared BusinessPartnerModel).
///
/// Payment (cash vs. online bank-gateway) is its own step, same as Food's
/// CustomerPaymentScreen — see [_continueToPayment] and the generic
/// PaymentScreen. This screen only owns the quantity/weight stepper, notes
/// and (via AddressController) fulfillment choice, which is why it stays a
/// StatefulWidget rather than a controller: that's purely local UI state,
/// not shared with any other screen.
class CosmeticCheckoutScreen extends StatefulWidget {
  const CosmeticCheckoutScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<CosmeticCheckoutScreen> createState() => _CosmeticCheckoutState();
}

class _CosmeticCheckoutState extends State<CosmeticCheckoutScreen> {
  int _quantity = 1;
  double _weightKg = 1;
  final _notesCtrl = TextEditingController();
  final AddressController addressController = Get.find();

  @override
  void initState() {
    super.initState();
    // Every checkout starts fresh in pickup mode, same as Food's — see
    // AddressController.resetDeliveryMode's doc comment.
    addressController.resetDeliveryMode();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _availableQuantity =>
      (widget.product.quantityAvailable ?? 0).toDouble();
  double get _availableWeightKg => widget.product.weightAvailableKg ?? 0;

  double get _unitPrice {
    final p = widget.product;
    return double.tryParse(
          (p.isWeightBased ? p.pricePerKg?.toString() : p.price) ?? '0',
        ) ??
        0;
  }

  double get _subtotal => widget.product.isWeightBased
      ? _unitPrice * _weightKg
      : _unitPrice * _quantity;

  // The server decides the real fee from whether deliveryAddress is present
  // in the request — this is display-only and must track the same toggle,
  // same contract as Food's OrderCheckoutScreen.deliveryFee.
  double get _deliveryFee => addressController.isDelivery.value
      ? (double.tryParse(widget.product.businessPartner?.deliveryFee ?? '0') ??
            0)
      : 0.0;
  double get _total => _subtotal + _deliveryFee;

  String get _quantityLabel {
    final product = widget.product;
    final qty = product.isWeightBased
        ? CurrencyFormatter.formatWeight(_weightKg, decimals: 2)
        : CustomerPaymentStrings.quantityLabel(_quantity);
    final businessName = product.businessPartner?.businessName ?? '';
    return businessName.isEmpty ? qty : '$businessName  ·  $qty';
  }

  Future<void> _onConfirm(BuildContext context, PaymentController ctrl) async {
    final product = widget.product;
    final partner = product.businessPartner;
    if (partner == null) return;

    final isDelivery = addressController.isDelivery.value;
    final address = addressController.selectedAddress.value;

    final orderCtrl = Get.find<ProductOrderController>();
    final ok = await orderCtrl.placeOrder(
      businessPartnerIri: partner.iri,
      deliveryAddressIri: isDelivery ? address!.iri : null,
      notes: _notesCtrl.text.trim(),
      paymentMethod: ctrl.paymentMethod.value,
      items: [
        {
          'product': product.iri,
          'quantity': product.isWeightBased ? 1 : _quantity,
          if (product.isWeightBased) 'weightKg': _weightKg.toStringAsFixed(2),
        },
      ],
    );

    if (ok) {
      Get.find<ProductController>(tag: 'cosmetic').fetchProducts();
      AppSnackbar.success(
        CosmeticStrings.checkoutSuccessTitle,
        CosmeticStrings.checkoutSuccessBody,
      );
      // Mirrors Food's OrderController.placeOrder: success returns all the
      // way to the first screen rather than just one step back, regardless
      // of whether checkout+payment is one or two screens deep.
      Get.until((route) => route.isFirst);
    } else {
      AppSnackbar.error(
        CosmeticStrings.checkoutErrorTitle,
        orderCtrl.placeOrderError.value ??
            CosmeticStrings.checkoutNotEnoughStock,
      );
    }
  }

  void _continueToPayment() {
    final product = widget.product;
    Get.to(
      () => PaymentScreen(
        config: PaymentScreenConfig(
          items: [
            OrderLineItem(
              title: product.title,
              imageUrl: product.images.isNotEmpty
                  ? product.images.first.url
                  : null,
              quantityLabel: _quantityLabel,
              totalPrice: _subtotal,
            ),
          ],
          subtotal: _subtotal,
          deliveryFee: _deliveryFee,
          total: _total,
          cashAvailable: product.businessPartner?.acceptsCashPayment == true,
          isPlacingOrder: Get.find<ProductOrderController>().isPlacingOrder,
          onConfirm: _onConfirm,
        ),
      ),
      binding: PaymentScreenBinding(),
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.navy,
        title: Text(
          CosmeticStrings.checkoutAppBarTitle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          children: [
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            if (product.businessPartner?.businessName.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                product.businessPartner!.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.gray600, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),

            Text(
              CosmeticStrings.checkoutQuantityLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            _quantityOrWeightStepper(),
            const SizedBox(height: 20),

            DeliveryToggle(addressController: addressController),
            Obx(() {
              if (!addressController.isDelivery.value) {
                return const SizedBox.shrink();
              }
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: BuildAddressPickerWidget(),
              );
            }),
            Obx(() {
              if (!addressController.isDelivery.value ||
                  addressController.isLoading.value ||
                  addressController.addresses.isNotEmpty) {
                return const SizedBox.shrink();
              }
              return const Padding(
                padding: EdgeInsets.only(top: 12),
                child: NoAddressBanner(),
              );
            }),
            const SizedBox(height: 20),

            Text(
              CosmeticStrings.checkoutNotesLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: CosmeticStrings.checkoutNotesHint,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Obx(
              () => BuildPriceBreakDownrWidget(
                subtotal: _subtotal,
                deliveryFee: _deliveryFee,
                total: _total,
              ),
            ),
            const SizedBox(height: 20),

            Obx(() {
              final isVerified =
                  Get.find<AuthController>().isEmailVerified.value;
              final hasRequiredAddress =
                  !addressController.isDelivery.value ||
                  addressController.selectedAddress.value != null;
              final canProceed = isVerified && hasRequiredAddress;
              return FilledButton(
                onPressed: canProceed ? _continueToPayment : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(CustomerPaymentStrings.proceedToPaymentButton),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _quantityOrWeightStepper() {
    final product = widget.product;
    if (product.isWeightBased) {
      return _StepperRow(
        value: '${_weightKg.toStringAsFixed(1)} kg',
        onDecrease: _weightKg > (product.minOrderKg ?? 0.1)
            ? () => setState(
                () => _weightKg = (_weightKg - 0.5).clamp(
                  0.1,
                  _availableWeightKg,
                ),
              )
            : null,
        onIncrease: _weightKg < _availableWeightKg
            ? () => setState(
                () => _weightKg = (_weightKg + 0.5).clamp(
                  0.1,
                  _availableWeightKg,
                ),
              )
            : null,
      );
    }
    return _StepperRow(
      value: '$_quantity',
      onDecrease: _quantity > 1 ? () => setState(() => _quantity--) : null,
      onIncrease: _quantity < _availableQuantity
          ? () => setState(() => _quantity++)
          : null,
    );
  }
}

/// Reusable +/- stepper row — factored out since the quantity and weight
/// steppers above share the same layout.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            color: AppColors.navy,
            onPressed: onDecrease,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColors.successDark,
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}
