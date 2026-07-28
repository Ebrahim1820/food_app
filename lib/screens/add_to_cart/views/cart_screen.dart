import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/constants/add_to_cart/cart_strings.dart';
import 'package:food_app/controllers/cart_controller.dart';
import 'package:food_app/models/cart_item.dart';
import 'package:food_app/screens/add_to_cart/views/cart_checkout_screen.dart';
import 'package:food_app/screens/add_to_cart/views/cart_revalidation_dialog.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/profile_and_orders/profile/views/qty_step_button.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/widgets/common/confirm_dialog.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';
import 'package:get/get.dart';

/// The one cart screen, shared by every market — [CartItem] carries no
/// market-specific type, so this file has zero knowledge of what a "food
/// offer" or "cosmetic product" is, the same way the generic PaymentScreen
/// doesn't either.
///
/// Re-validates every item's live availability on open (see
/// [CartController.revalidateAll]) — a cart can sit untouched for a while,
/// and an item can sell out or expire in the meantime, so this is the first
/// chance to catch that rather than finding out only after a failed
/// payment attempt.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartController get _cart => Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await _cart.revalidateAll();
      if (!mounted) return;
      await showCartRevalidationChanges(context, result);
    });
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.remove_shopping_cart_rounded,
      title: CartStrings.clearConfirmTitle,
      body: CartStrings.clearConfirmBody,
      confirmLabel: CartStrings.clearConfirmConfirm,
      cancelLabel: CartStrings.clearConfirmCancel,
    );
    if (confirmed == true) _cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final name = _cart.businessName.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CartStrings.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (name.isNotEmpty)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          );
        }),
        actions: [
          Obx(
            () => _cart.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _confirmClear(context),
                    child: Text(
                      CartStrings.clearButton,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (_cart.isEmpty) return const _EmptyCart();

          final content = Column(
            children: [
              Obx(
                () => _cart.isRevalidating.value
                    ? const LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.primary,
                        backgroundColor: AppColors.gray100,
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    safe.left + 16,
                    16,
                    safe.right + 16,
                    16,
                  ),
                  itemCount: _cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _CartItemRow(item: _cart.items[i], cart: _cart),
                ),
              ),
              _CartBottomBar(cart: _cart, safeBottom: safe.bottom),
            ],
          );

          // Tablets/landscape: cap the reading width and center it instead
          // of stretching item rows edge-to-edge across a much wider screen.
          if (!isLandscape) return content;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: content,
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: CartStrings.emptyTitle,
              subtitle: CartStrings.emptySubtitle,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                CartStrings.browseButton,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item, required this.cart});

  final CartItem item;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkImageWidget(
            imageUrl: item.imageUrl,
            height: 56,
            width: 56,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.isWeightBased
                      ? CurrencyFormatter.perKg(item.unitPrice)
                      : CurrencyFormatter.format(item.unitPrice),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.isWeightBased
                      ? CartStrings.availableLeft(
                          CurrencyFormatter.formatWeight(
                            item.maxWeightKg,
                            decimals: 1,
                          ),
                        )
                      : CartStrings.availableLeft(
                          '${item.maxQuantity.toInt()}',
                        ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.isWeightBased)
                  _WeightStepper(item: item, cart: cart)
                else
                  _QuantityStepper(item: item, cart: cart),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.textHint,
                ),
                onPressed: () => cart.removeItem(item.itemIri),
              ),
              Text(
                CurrencyFormatter.format(item.lineTotal),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatefulWidget {
  const _QuantityStepper({required this.item, required this.cart});

  final CartItem item;
  final CartController cart;

  @override
  State<_QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<_QuantityStepper> {
  late final TextEditingController _ctrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: CurrencyFormatter.localizeDigits('${widget.item.quantity}'),
    );
  }

  @override
  void didUpdateWidget(_QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Catches changes that didn't come from this widget's own +/-/typing
    // handlers — e.g. `CartController.revalidateAll()` clamping the
    // quantity down after stock dropped. Those already write `_ctrl.text`
    // themselves, so this is a no-op for them; skipped while focused so it
    // never fights an in-progress keystroke.
    if (!_focusNode.hasFocus) {
      final digits = CurrencyFormatter.localizeDigits(
        '${widget.item.quantity}',
      );
      if (_ctrl.text != digits) _ctrl.text = digits;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setText(int v) {
    final text = CurrencyFormatter.localizeDigits('$v');
    _ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // Tapping +/- doesn't reliably blur this field, so it writes the
  // displayed text itself rather than relying on a rebuild to resync it.
  // `widget.item` is the same mutable CartItem instance the controller
  // mutates in place, so re-reading its `quantity` right after the call
  // already reflects the new value — no manual +1/-1 bookkeeping needed.
  void _decrement() {
    widget.cart.decrementQuantity(widget.item.itemIri);
    _setText(widget.item.quantity);
  }

  void _increment() {
    if (widget.item.quantity >= widget.item.maxQuantity) return;
    widget.cart.incrementQuantity(widget.item.itemIri);
    _setText(widget.item.quantity);
  }

  void _handleTyped(String text) {
    if (text.isEmpty) return;
    final parsed = CurrencyFormatter.parseLocalizedDouble(text).round();
    widget.cart.setQuantity(widget.item.itemIri, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isInvalid =
        widget.item.quantity < 1 ||
        widget.item.quantity > widget.item.maxQuantity;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QtyStepButton(icon: Icons.remove, onTap: _decrement),
        SizedBox(
          width: 36,
          height: 22,
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹]')),
            ],
            onChanged: _handleTyped,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isInvalid ? AppColors.error : AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
        QtyStepButton(
          icon: Icons.add,
          onTap: widget.item.quantity < widget.item.maxQuantity
              ? _increment
              : null,
        ),
      ],
    );
  }
}

class _WeightStepper extends StatefulWidget {
  const _WeightStepper({required this.item, required this.cart});

  final CartItem item;
  final CartController cart;

  @override
  State<_WeightStepper> createState() => _WeightStepperState();
}

class _WeightStepperState extends State<_WeightStepper> {
  late final TextEditingController _ctrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: CurrencyFormatter.formatWeight(widget.item.weightKg, decimals: 1),
    );
  }

  @override
  void didUpdateWidget(_WeightStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // See the matching comment in _QuantityStepperState — catches changes
    // from outside this widget (e.g. revalidateAll clamping stock down)
    // without fighting an in-progress keystroke.
    if (!_focusNode.hasFocus) {
      final text = CurrencyFormatter.formatWeight(
        widget.item.weightKg,
        decimals: 1,
      );
      if (_ctrl.text != text) _ctrl.text = text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setText(double kg) {
    final text = CurrencyFormatter.formatWeight(kg, decimals: 1);
    _ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // Tapping +/- doesn't reliably blur this field, so it writes the
  // displayed text itself — `widget.item` is the same mutable CartItem
  // instance the controller mutates in place, so re-reading `weightKg`
  // right after the call already reflects the new (clamped) value.
  void _decrement() {
    widget.cart.setWeight(widget.item.itemIri, widget.item.weightKg - 0.5);
    _setText(widget.item.weightKg);
  }

  void _increment() {
    widget.cart.setWeight(widget.item.itemIri, widget.item.weightKg + 0.5);
    _setText(widget.item.weightKg);
  }

  void _handleTyped(String text) {
    if (text.isEmpty) return;
    final parsed = CurrencyFormatter.parseLocalizedDouble(text);
    widget.cart.setWeightRaw(widget.item.itemIri, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isInvalid =
        widget.item.weightKg < widget.item.minWeightKg ||
        widget.item.weightKg > widget.item.maxWeightKg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QtyStepButton(icon: Icons.remove, onTap: _decrement),
        SizedBox(
          width: 64,
          height: 22,
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,۰-۹]')),
            ],
            onChanged: _handleTyped,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isInvalid ? AppColors.error : AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
        QtyStepButton(
          icon: Icons.add,
          onTap: widget.item.weightKg < widget.item.maxWeightKg
              ? _increment
              : null,
        ),
      ],
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({required this.cart, required this.safeBottom});

  final CartController cart;
  final double safeBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + safeBottom),
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
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CustomerOrderStrings.itemCount(cart.itemCount),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${CartStrings.subtotalLabel}  ${CurrencyFormatter.format(cart.subtotal)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (cart.hasInvalidItem) ...[
              const SizedBox(height: 8),
              Text(
                CartStrings.invalidQuantityWarning,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.errorDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: cart.hasInvalidItem
                    ? null
                    : () => Get.to(() => const CartCheckoutScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  foregroundColor: AppColors.white,
                  disabledForegroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  CartStrings.proceedButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
