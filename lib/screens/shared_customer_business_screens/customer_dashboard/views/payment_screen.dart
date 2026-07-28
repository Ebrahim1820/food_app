// Generic checkout payment step — hero amount card, itemised order summary,
// cash-vs-online-gateway selector (see PspGatewaySelector) and a sticky pay
// button.
//
// Reusable across markets the same way ProductDetailScreen/OrderListScreen
// are: a market wiring layer (e.g. CustomerPaymentScreen for Food,
// CosmeticCheckoutScreen's payment step for Cosmetic) extracts plain values
// out of its own model into a [PaymentScreenConfig] and owns everything
// market-specific about actually placing the order — address validation,
// building the items payload, which controller's placeOrder to call. This
// file never imports a market model and has zero knowledge of what a "food
// offer" or "cosmetic product" is.
import 'package:flutter/material.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/widgets/common/item_image_carousel.dart';
import 'package:food_app/profile_and_orders/orders/controllers/payment_controller.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_payment_strings.dart';
import 'package:food_app/profile_and_orders/orders/views/order_line_items_card.dart';
import 'package:food_app/profile_and_orders/orders/views/psp_gateway_selector.dart';
import 'package:food_app/services/user_service.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/widgets/email_verification_banner.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG — everything the generic screen needs, extracted by the caller
// ─────────────────────────────────────────────────────────────────────────────

class PaymentScreenConfig {
  const PaymentScreenConfig({
    required this.items,
    required this.subtotal,
    this.deliveryFee = 0,
    required this.total,
    required this.cashAvailable,
    required this.isPlacingOrder,
    required this.onConfirm,
  });

  /// What's being bought — one entry today for both Food and Cosmetic (no
  /// cart yet), but the hero banner and items card both already handle any
  /// number: a single item renders as one big photo, more than one becomes
  /// a swipeable image slider plus a "N items" list.
  final List<OrderLineItem> items;

  final double subtotal;

  /// 0 hides the delivery-fee row entirely (pickup orders).
  final double deliveryFee;
  final double total;

  /// Whether this seller accepts cash — hides the cash/online toggle
  /// entirely when false (online-only).
  final bool cashAvailable;

  /// Reflects whichever market controller actually places the order
  /// (OrderController for Food, ProductOrderController for Cosmetic, ...).
  final RxBool isPlacingOrder;

  /// Everything about actually placing the order — address checks, building
  /// the items payload, calling the right controller — lives here, not in
  /// this generic screen. Called only after this screen's own
  /// cash/online-gateway validation (`ctrl.canPay`) already passed.
  final Future<void> Function(BuildContext context, PaymentController ctrl)
  onConfirm;
}

// ─────────────────────────────────────────────────────────────────────────────
// BINDING
// ─────────────────────────────────────────────────────────────────────────────

class PaymentScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentController>(() => PaymentController());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.config});

  final PaymentScreenConfig config;

  PaymentController get ctrl => Get.find<PaymentController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroBanner(items: config.items, total: config.total),
                    const SizedBox(height: 20),
                    OrderLineItemsCard(items: config.items),
                    const SizedBox(height: 20),
                    _OrderSummaryCard(
                      subtotal: config.subtotal,
                      deliveryFee: config.deliveryFee,
                      total: config.total,
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      final authCtrl = Get.find<AuthController>();
                      if (authCtrl.isEmailVerified.value) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: EmailVerificationBannerWidget(
                          email: authCtrl.email,
                          onResend: () => Get.find<UserService>()
                              .resendVerificationEmail(authCtrl.email),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    _PaymentMethodSection(
                      ctrl: ctrl,
                      cashAvailable: config.cashAvailable,
                    ),
                    const SizedBox(height: 32),
                    const _SecurityBadge(),
                  ],
                ),
              ),
            ),
            _PayBottomBar(ctrl: ctrl, config: config),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
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
      CustomerPaymentStrings.appBarTitle,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppColors.divider),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BANNER — bigger image up top (a slider when there's more than one
// item), the running total below it.
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final List<OrderLineItem> items;
  final double total;

  const _HeroBanner({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final summaryLabel = items.length == 1
        ? items.first.title
        : CustomerOrderStrings.itemCount(items.length);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ItemImageCarousel(
            imageUrls: items.map((e) => e.imageUrl).toList(),
            height: 180,
            borderRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      CustomerPaymentStrings.totalLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER SUMMARY CARD — itemised breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;

  const _OrderSummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final showDeliveryFee = deliveryFee > 0;
    return _SectionCard(
      title: CustomerPaymentStrings.orderSummaryTitle,
      child: Column(
        children: [
          _SummaryRow(
            label: CustomerPaymentStrings.subtotalLabel,
            value: CurrencyFormatter.format(subtotal),
          ),
          if (showDeliveryFee) ...[
            const SizedBox(height: 10),
            _SummaryRow(
              label: CustomerPaymentStrings.deliveryLabel,
              value: CurrencyFormatter.format(deliveryFee),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _SummaryRow(
            label: CustomerPaymentStrings.totalLabel,
            value: CurrencyFormatter.format(total),
            isBold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isBold ? 16 : 14,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
      color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: style.copyWith(color: valueColor ?? style.color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT METHOD SECTION — cash vs. online bank-gateway redirect
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodSection extends StatelessWidget {
  final PaymentController ctrl;
  final bool cashAvailable;

  const _PaymentMethodSection({
    required this.ctrl,
    required this.cashAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: CustomerPaymentStrings.paymentMethodTitle,
      child: Obx(() {
        final isCash = ctrl.isCash;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cashAvailable) ...[
              _MethodToggleRow(
                isCash: isCash,
                onSelectCard: () => ctrl.paymentMethod.value = 'card',
                onSelectCash: () => ctrl.paymentMethod.value = 'cash',
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 16),
            ],
            if (isCash)
              const _CashInfoPanel()
            else
              PspGatewaySelector(
                selected: ctrl.selectedPsp.value,
                onSelect: (p) => ctrl.selectedPsp.value = p,
              ),
          ],
        );
      }),
    );
  }
}

// ── Method toggle (Online / Cash) ─────────────────────────────────────────────

class _MethodToggleRow extends StatelessWidget {
  final bool isCash;
  final VoidCallback onSelectCard;
  final VoidCallback onSelectCash;

  const _MethodToggleRow({
    required this.isCash,
    required this.onSelectCard,
    required this.onSelectCash,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodTile(
            icon: Icons.account_balance_rounded,
            label: CustomerPaymentStrings.payOnlineLabel,
            sublabel: CustomerPaymentStrings.payOnlineSublabel,
            selected: !isCash,
            accentColor: AppColors.primary,
            onTap: onSelectCard,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MethodTile(
            icon: Icons.payments_outlined,
            label: CustomerPaymentStrings.payAtPickupLabel,
            sublabel: CustomerPaymentStrings.payAtPickupSublabel,
            selected: isCash,
            accentColor: AppColors.warning,
            onTap: onSelectCash,
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.07)
              : AppColors.gray50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accentColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withValues(alpha: 0.12)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? accentColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? accentColor : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: selected ? accentColor : AppColors.gray300,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: AppColors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cash info panel ───────────────────────────────────────────────────────────

class _CashInfoPanel extends StatelessWidget {
  const _CashInfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.warningDark,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CustomerPaymentStrings.payAtPickupLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warningDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.warning),
          const SizedBox(height: 14),
          _CashInfoRow(
            icon: Icons.check_circle_outline_rounded,
            text: CustomerPaymentStrings.cashNoCardHint,
          ),
          const SizedBox(height: 8),
          _CashInfoRow(
            icon: Icons.schedule_rounded,
            text: CustomerPaymentStrings.cashExactAmountHint,
          ),
          const SizedBox(height: 8),
          _CashInfoRow(
            icon: Icons.info_outline_rounded,
            text: CustomerPaymentStrings.reservedInfo,
          ),
        ],
      ),
    );
  }
}

class _CashInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CashInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.warningDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.warningDark,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECURITY BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 14, color: AppColors.textHint),
        SizedBox(width: 6),
        Text(
          CustomerPaymentStrings.securityLine,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAY BUTTON BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────

class _PayBottomBar extends StatelessWidget {
  final PaymentController ctrl;
  final PaymentScreenConfig config;

  const _PayBottomBar({required this.ctrl, required this.config});

  Future<void> _handlePay(BuildContext context) async {
    if (!ctrl.canPay) {
      AppSnackbar.error('', CustomerPaymentStrings.selectPaymentMethodError);
      return;
    }
    await config.onConfirm(context, ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final placing = config.isPlacingOrder.value;
          final isVerified = Get.find<AuthController>().isEmailVerified.value;
          final canPay = ctrl.canPay && isVerified;
          final isCash = ctrl.isCash;

          final gradient = canPay
              ? (isCash
                    ? const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : const LinearGradient(
                        colors: [AppColors.primary, AppColors.primary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ))
              : null;

          final shadowColor = isCash
              ? AppColors.warning.withValues(alpha: 0.45)
              : AppColors.primary.withValues(alpha: 0.4);

          return SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                color: canPay ? null : AppColors.gray200,
                borderRadius: BorderRadius.circular(16),
                boxShadow: canPay
                    ? [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: (placing || !canPay)
                    ? null
                    : () => _handlePay(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: placing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            CustomerPaymentStrings.processingLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCash
                                ? Icons.payments_outlined
                                : Icons.lock_rounded,
                            size: 18,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCash
                                ? CustomerPaymentStrings.confirmAtPickup
                                : CustomerPaymentStrings.payButton(
                                    CurrencyFormatter.format(config.total),
                                  ),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
