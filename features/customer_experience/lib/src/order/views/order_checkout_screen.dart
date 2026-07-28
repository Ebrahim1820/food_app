import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:profile/profile.dart';
import 'package:auth/auth.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';
import 'package:notification/notification.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';

class OrderCheckoutScreen extends StatelessWidget {
  // The offer as it looked on the list/detail screen the user came from —
  // often stale by the time they reach checkout (list is cache-then-network,
  // and stock can sell out between screens). [offer] below always reads the
  // freshly-refetched version once _refreshOffer() completes, so the
  // quantity stepper's max bound and the price shown here track real stock
  // instead of silently letting the user select more than's left.
  final Rx<FoodOfferModel> _offerRx;
  FoodOfferModel get offer => _offerRx.value;

  final AddressController addressController = Get.find();
  final OrderService _orderService = OrderService(Get.find<ApiService>());

  OrderCheckoutScreen({required FoodOfferModel offer, super.key})
    : _offerRx = Rx(offer) {
    // This is a pickup-first marketplace — every checkout starts fresh in
    // pickup mode regardless of what a previous order used. Deferred to after
    // the first frame: calling this synchronously here mutates Rx values
    // while the pushed route's Builder is still building, which can hit
    // another Obx mid-rebuild elsewhere and trip Flutter's "setState during
    // build" guard (stays a StatelessWidget on purpose — no initState needed
    // for this, addPostFrameCallback works fine from a constructor).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addressController.resetDeliveryMode();
    });
    _refreshOffer();
  }

  Future<void> _refreshOffer() async {
    final fresh = await _orderService.getFoodOfferByIri(offer.iri);
    if (fresh == null) return;
    _offerRx.value = fresh;
    // A quantity/weight picked against the stale bound may no longer be
    // valid — clamp it down rather than letting the user submit an order
    // for more than is actually left.
    final availableQty = fresh.quantityAvailable;
    if (availableQty != null && quantity.value > availableQty) {
      quantity.value = availableQty.clamp(1, availableQty);
    }
    final availableKg = fresh.weightAvailableKg;
    if (availableKg != null && weightKg.value > availableKg) {
      weightKg.value = availableKg;
      _weightCtrl.text = availableKg.toStringAsFixed(1);
    }
  }

  final OrderController controller = Get.find<OrderController>();

  // Piece-based quantity
  final RxInt quantity = 1.obs;

  // Weight-based amount (in kg)
  final RxDouble weightKg = 0.5.obs;
  final TextEditingController _weightCtrl = TextEditingController(text: '0.5');

  final RxBool isLoading = false.obs;
  final TextEditingController notesController = TextEditingController();

  double get subtotal {
    if (offer.isWeightBased) {
      return weightKg.value * (offer.pricePerKg ?? 0);
    }
    return (double.tryParse(offer.price ?? '0') ?? 0) * quantity.value;
  }

  // The server decides the real fee from whether deliveryAddress is present
  // in the request — this is display-only and must track the same toggle.
  double get deliveryFee => addressController.isDelivery.value
      ? double.parse(offer.businessPartner!.deliveryFee)
      : 0.0;
  double get total => subtotal + deliveryFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CustomerCheckoutStrings.appBarTitle)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BuildOfferInfoWidget(offer: offer),
                if (offer.isSoldOut) ...[
                  const SizedBox(height: 12),
                  const _SoldOutBanner(),
                ],
                const SizedBox(height: 24),

                // Weight input or quantity stepper depending on offer type
                if (offer.isWeightBased)
                  _WeightInputWidget(
                    offer: offer,
                    weightKg: weightKg,
                    weightCtrl: _weightCtrl,
                  )
                else
                  QuantityStepperField(
                    quantity: quantity,
                    maxQuantity: offer.quantityAvailable ?? 999,
                  ),

                const SizedBox(height: 24),
                DeliveryToggle(addressController: addressController),
                Obx(() {
                  if (!addressController.isDelivery.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
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
                const SizedBox(height: 24),
                BuildNotesFieldWidget(),
                const SizedBox(height: 24),
                Obx(
                  () => BuildPriceBreakDownrWidget(
                    subtotal: subtotal,
                    deliveryFee: deliveryFee,
                    total: total,
                  ),
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final authCtrl = Get.find<AuthController>();
                  if (authCtrl.isEmailVerified.value)
                    return const SizedBox.shrink();
                  return EmailVerificationBannerWidget(
                    email: authCtrl.email,
                    onResend: () => Get.find<UserService>()
                        .resendVerificationEmail(authCtrl.email),
                  );
                }),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => BuildConfirmButtonWidget(
          offer: offer,
          quantity: quantity,
          weightKg: offer.isWeightBased ? weightKg : null,
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          total: total,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sold-out banner — shown when the refreshed offer has no stock left.
// ---------------------------------------------------------------------------

class _SoldOutBanner extends StatelessWidget {
  const _SoldOutBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 18,
            color: AppColors.gray500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              OfferStatusLabels.soldOut,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No-address banner — shown when the user has no saved delivery addresses.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Weight input widget shown instead of quantity stepper for weight-based offers.
// ---------------------------------------------------------------------------
class _WeightInputWidget extends StatelessWidget {
  const _WeightInputWidget({
    required this.offer,
    required this.weightKg,
    required this.weightCtrl,
  });

  final FoodOfferModel offer;
  final RxDouble weightKg;
  final TextEditingController weightCtrl;

  @override
  Widget build(BuildContext context) {
    final available = offer.weightAvailableKg ?? 0;
    final minOrder = offer.minOrderKg ?? 0;
    final perKg = offer.pricePerKg ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.scale_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Weight (kg)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.isFarsi
                    ? '${CurrencyFormatter.localizeDigits(available.toStringAsFixed(1))} ${CurrencyFormatter.faKgUnit} موجود'
                    : '${available.toStringAsFixed(1)} kg available',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (minOrder > 0) ...[
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.isFarsi
                  ? 'حداقل سفارش: ${CurrencyFormatter.localizeDigits(minOrder.toStringAsFixed(1))} ${CurrencyFormatter.faKgUnit}'
                  : 'Min. order: ${minOrder.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _stepBtn(
                icon: Icons.remove,
                enabled: weightKg.value > (minOrder > 0 ? minOrder : 0.5),
                onTap: () {
                  final next = (weightKg.value - 0.5).clamp(
                    minOrder > 0 ? minOrder : 0.5,
                    available,
                  );
                  weightKg.value = double.parse(next.toStringAsFixed(1));
                  weightCtrl.text = weightKg.value.toStringAsFixed(1);
                },
              ),
              Expanded(
                child: TextFormField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    suffixText: 'kg',
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v) ?? 0;
                    weightKg.value = parsed.clamp(0.0, available);
                  },
                ),
              ),
              _stepBtn(
                icon: Icons.add,
                enabled: weightKg.value < available,
                onTap: () {
                  final next = (weightKg.value + 0.5).clamp(0.0, available);
                  weightKg.value = double.parse(next.toStringAsFixed(1));
                  weightCtrl.text = weightKg.value.toStringAsFixed(1);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final calc = weightKg.value * perKg;
            final wStr = CurrencyFormatter.localizeDigits(
              weightKg.value.toStringAsFixed(1),
            );
            final calcLabel = CurrencyFormatter.isFarsi
                ? '$wStr ${CurrencyFormatter.faKgUnit} × ${CurrencyFormatter.perKg(perKg)} = ${CurrencyFormatter.format(calc)}'
                : '${weightKg.value.toStringAsFixed(1)} kg × ${CurrencyFormatter.perKg(perKg)} = ${CurrencyFormatter.format(calc)}';
            return Text(
              calcLabel,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.successDark,
                fontWeight: FontWeight.w600,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.gray300,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}
