import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import '../../discovery/views/order_detail_screen.dart'
    show isPendingOrderStatus, isTerminalOrderStatus;
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';

/// UI-only helpers layered on top of the shared [OrderModel].
///
/// Kept as an extension so the domain model stays clean and serialisation-free.
/// [OrderBucket] is defined in app_enums.dart alongside all other enums.
extension OrderModelUi on OrderModel {
  double get totalPriceValue => double.tryParse(totalPrice) ?? 0;
  double get deliveryFeeValue => double.tryParse(deliveryFee) ?? 0;

  int get itemCount => orderItems.fold(0, (sum, i) => sum + i.quantity);

  /// Infers delivery vs. pickup from the address presence and fee amount.
  bool get isDelivery =>
      (deliveryAddress?.isNotEmpty ?? false) && deliveryFeeValue > 0;

  /// Maps the raw status string to the correct [OrderBucket] tab.
  /// Inverted logic: only known terminal statuses go to Done.
  /// Any unknown in-progress status stays in Active rather than disappearing.
  OrderBucket get bucket {
    if (isPendingOrderStatus(status)) return OrderBucket.incoming;
    if (isTerminalOrderStatus(status)) return OrderBucket.done;
    return OrderBucket.active;
  }

  /// Only the first state needs an Accept / Reject decision.
  bool get needsDecision => isPendingOrderStatus(status);

  DateTime? get createdAtDate => DateTime.tryParse(createdAt);

  String get elapsedLabel {
    final d = createdAtDate;
    if (d == null) return '';
    final mins = DateTime.now().difference(d).inMinutes;
    if (mins < 1) return 'just now';
    if (mins < 60) return '${CurrencyFormatter.localizeDigits('$mins')} min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${CurrencyFormatter.localizeDigits('$h')}h ${CurrencyFormatter.localizeDigits('$m')}m';
  }

  String get totalLabel => CurrencyFormatter.format(totalPriceValue);

  String get itemCountLabel {
    final n = CurrencyFormatter.localizeDigits('$itemCount');
    return itemCount == 1
        ? 'custOrder_itemCountOne'.trParams({'n': n})
        : 'custOrder_itemCountOther'.trParams({'n': n});
  }

  String get statusLabel => switch (status) {
    'pending' => 'orderStatus_new'.tr,
    'confirmed' => 'orderStatus_confirmed'.tr,
    'preparing' => 'orderStatus_preparing'.tr,
    // Backend's actual enum value is 'ready_for_pickup' (see
    // OrderStatusEnums.readyForPickup.value) — 'ready' kept for back-compat
    // with any older data that used the shorter form.
    'ready' || 'ready_for_pickup' => 'orderStatus_ready'.tr,
    'delivered' || 'completed' => 'orderStatus_delivered'.tr,
    'cancelled' => 'orderStatus_cancelled'.tr,
    _ => status,
  };
}
