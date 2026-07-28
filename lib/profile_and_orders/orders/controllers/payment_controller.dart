import 'package:food_app/enums/app_enums.dart';
import 'package:get/get.dart';

/// Checkout-step payment state — shared by every market (Food, Cosmetic,
/// ...). "Online" payment here always means picking one of the domestic PSP
/// gateways in [PspProvider] (see its doc comment for why there's no
/// in-app card-number entry): the actual redirect/confirm round-trip isn't
/// wired up yet (no backend API for it today), so [selectedPsp] is
/// currently just UI selection state carried through to `placeOrder`.
class PaymentController extends GetxController {
  // ── Payment method: 'card' (= pay online via a PSP) | 'cash' ─────────────
  // Kept as this exact string pair since OrderService/ProductOrderService
  // already send it to the backend as-is.
  final paymentMethod = 'card'.obs;

  bool get isCash => paymentMethod.value == 'cash';

  // ── Online-gateway selection ──────────────────────────────────────────────
  final selectedPsp = Rxn<PspProvider>();

  // ── Processing indicator ─────────────────────────────────────────────────
  final isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    selectedPsp.value = PspProvider.enabledProviders.isNotEmpty
        ? PspProvider.enabledProviders.first
        : null;
  }

  bool get canPay => isCash || selectedPsp.value != null;
}
