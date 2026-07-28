import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:models/models.dart';
import 'package:payment/payment.dart';
import 'package:profile/profile.dart';
import '../../discovery/views/payment_screen.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Fulfillment step for a whole cart (potentially several items, all from
/// the same business — see [CartController]) — the generic counterpart to
/// Food's `OrderCheckoutScreen`/Cosmetic's `CosmeticCheckoutScreen`, which
/// are both still single-item. Reuses the exact same building blocks those
/// screens do ([DeliveryToggle], [BuildAddressPickerWidget], [NoAddressBanner],
/// [BuildPriceBreakDownrWidget], [OrderLineItemsCard]) — this screen's only
/// job is picking pickup/delivery + notes, then handing off to the generic
/// [PaymentScreen] with every cart item.
///
/// Which controller actually places the order depends on
/// `CartController.market` ('food' → [OrderController], anything else →
/// [ProductOrderController]) — a cart is always scoped to one business, and
/// therefore always to one market.
class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final CartController cart = Get.find();
  final AddressController addressController = Get.find();
  final _notesCtrl = TextEditingController();

  bool get _isFood => cart.market.value == Market.food.value;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame: calling this synchronously here
    // mutates Rx values while this screen's own widget tree is still being
    // mounted, which can hit another Obx mid-rebuild elsewhere (e.g. during
    // the push transition) and trip Flutter's "setState during build" guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addressController.resetDeliveryMode();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _deliveryFee => addressController.isDelivery.value
      ? (double.tryParse(cart.businessDeliveryFee.value) ?? 0)
      : 0.0;
  double get _total => cart.subtotal + _deliveryFee;

  List<Map<String, dynamic>> get _itemsPayload => cart.items
      .map(
        (i) => {
          i.payloadKey: i.itemIri,
          'quantity': i.isWeightBased ? 1 : i.quantity,
          if (i.isWeightBased) 'weightKg': i.weightKg.toStringAsFixed(2),
          // Food's backend contract wants both keys for weight-based items;
          // Cosmetic's only wants weightKg.
          if (i.isWeightBased && _isFood)
            'weightTotalKg': i.weightKg.toStringAsFixed(2),
        },
      )
      .toList();

  Future<void> _onConfirm(BuildContext context, PaymentController ctrl) async {
    final businessIri = cart.businessPartnerIri.value;
    if (businessIri == null) return;

    final isDelivery = addressController.isDelivery.value;
    final address = addressController.selectedAddress.value;
    if (isDelivery && address == null) {
      AppSnackbar.error('', CustomerPaymentStrings.noAddressError);
      return;
    }

    if (_isFood) {
      final orderCtrl = Get.find<OrderController>();
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
      try {
        await orderCtrl.placeOrder(
          businessPartnerIri: businessIri,
          deliveryAddressIri: isDelivery ? address!.iri : null,
          notes: _notesCtrl.text.trim(),
          userIri: userIri,
          paymentMethod: ctrl.paymentMethod.value,
          items: _itemsPayload,
        );
        // placeOrder shows its own success snackbar and navigates to the
        // first screen; it rethrows on failure (and shows its own error
        // snackbar too), so reaching this line means it succeeded.
        cart.clear();
      } catch (_) {
        // Already surfaced to the user by placeOrder itself.
      }
      return;
    }

    final productOrderCtrl = Get.find<ProductOrderController>();
    final ok = await productOrderCtrl.placeOrder(
      businessPartnerIri: businessIri,
      deliveryAddressIri: isDelivery ? address!.iri : null,
      notes: _notesCtrl.text.trim(),
      paymentMethod: ctrl.paymentMethod.value,
      items: _itemsPayload,
    );
    if (ok) {
      Get.find<ProductController>(tag: Market.cosmetic.value).fetchProducts();
      cart.clear();
      AppSnackbar.success(
        CustomerOrderStrings.placedTitle,
        CustomerOrderStrings.placedBody,
      );
      Get.until((route) => route.isFirst);
    } else {
      AppSnackbar.error(
        ErrorStrings.title,
        productOrderCtrl.placeOrderError.value ??
            CustomerPaymentStrings.partnerNotFoundError,
      );
    }
  }

  Future<void> _proceedToPayment() async {
    final result = await cart.revalidateAll();
    if (!mounted) return;
    await showCartRevalidationChanges(context, result);
    if (!mounted) return;

    // Everything got removed — nothing left to check out, so return to the
    // cart screen (which will show its own empty state) rather than opening
    // a payment screen for zero items.
    if (cart.isEmpty) {
      Get.back();
      return;
    }

    final isPlacingOrder = _isFood
        ? Get.find<OrderController>().isPlacingOrder
        : Get.find<ProductOrderController>().isPlacingOrder;

    Get.to(
      () => PaymentScreen(
        config: PaymentScreenConfig(
          items: cart.items
              .map(
                (i) => OrderLineItem(
                  title: i.title,
                  imageUrl: i.imageUrl,
                  quantityLabel: i.isWeightBased
                      ? CurrencyFormatter.formatWeight(i.weightKg, decimals: 2)
                      : CustomerPaymentStrings.quantityLabel(i.quantity),
                  totalPrice: i.lineTotal,
                ),
              )
              .toList(),
          subtotal: cart.subtotal,
          deliveryFee: _deliveryFee,
          total: _total,
          cashAvailable: cart.businessAcceptsCash.value,
          isPlacingOrder: isPlacingOrder,
          onConfirm: _onConfirm,
        ),
      ),
      binding: PaymentScreenBinding(),
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          CartStrings.checkoutAppBarTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, safe.bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderLineItemsCard(items: _lineItemsPreview()),
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
                CustomerCheckoutStrings.notesLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: CustomerCheckoutStrings.notesHint,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => BuildPriceBreakDownrWidget(
                  subtotal: cart.subtotal,
                  deliveryFee: _deliveryFee,
                  total: _total,
                ),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final hasRequiredAddress =
                    !addressController.isDelivery.value ||
                    addressController.selectedAddress.value != null;
                final revalidating = cart.isRevalidating.value;
                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (hasRequiredAddress && !revalidating)
                        ? _proceedToPayment
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: revalidating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          )
                        : Row(
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
                            ],
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<OrderLineItem> _lineItemsPreview() => cart.items
      .map(
        (i) => OrderLineItem(
          title: i.title,
          imageUrl: i.imageUrl,
          quantityLabel: i.isWeightBased
              ? CurrencyFormatter.formatWeight(i.weightKg, decimals: 2)
              : CustomerPaymentStrings.quantityLabel(i.quantity),
          totalPrice: i.lineTotal,
        ),
      )
      .toList();
}
