import 'package:customer_experience/customer_experience.dart';
import 'package:get/get.dart';

/// What changed after [CartController.revalidateAll] — item titles only, so
/// the caller decides how to phrase the message shown to the user.
class CartRevalidationResult {
  const CartRevalidationResult({
    required this.removedTitles,
    required this.adjustedTitles,
  });

  /// Sold out / expired / deleted — removed from the cart entirely.
  final List<String> removedTitles;

  /// Still available, but quantity/weight got clamped down to the new
  /// (lower) live stock.
  final List<String> adjustedTitles;

  bool get hasChanges => removedTitles.isNotEmpty || adjustedTitles.isNotEmpty;
}

/// The one active cart — scoped to a single business at a time, the same
/// constraint real delivery apps (Uber Eats, DoorDash) enforce: you can add
/// as many items as you like from one restaurant/store, but adding from a
/// different business means starting a fresh order (see [canAddFrom] and
/// `confirmCartSwitch` in `cart_conflict_dialog.dart`, which gates every
/// [addItem] call from the UI side).
///
/// Registered globally (see InitialBinding) so a market's product-detail
/// screen, the cart screen and the cart checkout screen all share the same
/// instance — adding an item on one screen shows up everywhere else
/// immediately via the reactive [items] list.
class CartController extends GetxController {
  final items = <CartItem>[].obs;

  final businessPartnerIri = RxnString();
  final businessName = ''.obs;
  final businessDeliveryFee = '0.0'.obs;
  final businessAcceptsCash = true.obs;

  /// 'food' | 'cosmetic' | ... — which market controller's placeOrder to
  /// call once checkout confirms.
  final market = RxnString();

  final isRevalidating = false.obs;

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// True when any line's manually-typed quantity/weight is outside what's
  /// actually available — blocks "Proceed to checkout" until corrected.
  bool get hasInvalidItem => items.any(
    (item) => item.isWeightBased
        ? (item.weightKg < item.minWeightKg || item.weightKg > item.maxWeightKg)
        : (item.quantity < 1 || item.quantity > item.maxQuantity),
  );

  /// Whether [businessIri] can be added without wiping the cart first — true
  /// when the cart is empty or already belongs to that same business.
  bool canAddFrom(String businessIri) =>
      businessPartnerIri.value == null ||
      businessPartnerIri.value == businessIri;

  /// Adds [item], merging into an existing line (by [CartItem.itemIri]) if
  /// one's already in the cart. Callers must check [canAddFrom] first (via
  /// `confirmCartSwitch`) — this throws if [businessIri] conflicts with
  /// what's already in the cart, since that should never happen once the UI
  /// gates it.
  void addItem({
    required String businessIri,
    required String businessNameValue,
    required String businessDeliveryFeeValue,
    required bool businessAcceptsCashValue,
    required String marketValue,
    required CartItem item,
  }) {
    if (!canAddFrom(businessIri)) {
      throw StateError(
        'Cart belongs to a different business — call confirmCartSwitch first.',
      );
    }
    businessPartnerIri.value = businessIri;
    businessName.value = businessNameValue;
    businessDeliveryFee.value = businessDeliveryFeeValue;
    businessAcceptsCash.value = businessAcceptsCashValue;
    market.value = marketValue;

    final existing = items.firstWhereOrNull((e) => e.itemIri == item.itemIri);
    if (existing == null) {
      items.add(item);
      return;
    }
    if (item.isWeightBased) {
      existing.weightKg = (existing.weightKg + item.weightKg).clamp(
        existing.minWeightKg,
        existing.maxWeightKg,
      );
    } else {
      existing.quantity = (existing.quantity + item.quantity).clamp(
        1,
        existing.maxQuantity.toInt(),
      );
    }
    items.refresh();
  }

  void incrementQuantity(String itemIri) {
    final item = items.firstWhereOrNull((e) => e.itemIri == itemIri);
    if (item == null || item.quantity >= item.maxQuantity) return;
    item.quantity++;
    items.refresh();
  }

  void decrementQuantity(String itemIri) {
    final item = items.firstWhereOrNull((e) => e.itemIri == itemIri);
    if (item == null) return;
    if (item.quantity <= 1) {
      removeItem(itemIri);
      return;
    }
    item.quantity--;
    items.refresh();
  }

  /// Sets an exact quantity — used only when the customer types a value
  /// directly instead of tapping +/-. Deliberately does NOT clamp or
  /// remove on an out-of-range value the way +/- does: silently correcting
  /// a typed "6" back down to the real max of 5 left the checkout button
  /// thinking the quantity was still valid even though the box visibly
  /// showed 6 — see [hasInvalidItem], which is what now actually blocks
  /// proceeding to checkout on an out-of-range value.
  void setQuantity(String itemIri, int qty) {
    final item = items.firstWhereOrNull((e) => e.itemIri == itemIri);
    if (item == null) return;
    item.quantity = qty;
    items.refresh();
  }

  void setWeight(String itemIri, double kg) {
    final item = items.firstWhereOrNull((e) => e.itemIri == itemIri);
    if (item == null) return;
    if (kg < item.minWeightKg) {
      removeItem(itemIri);
      return;
    }
    item.weightKg = kg.clamp(item.minWeightKg, item.maxWeightKg);
    items.refresh();
  }

  /// Typed-entry counterpart to [setWeight] — see [setQuantity]'s doc
  /// comment for why this deliberately skips clamping/removal.
  void setWeightRaw(String itemIri, double kg) {
    final item = items.firstWhereOrNull((e) => e.itemIri == itemIri);
    if (item == null) return;
    item.weightKg = kg;
    items.refresh();
  }

  void removeItem(String itemIri) {
    items.removeWhere((e) => e.itemIri == itemIri);
    if (items.isEmpty) clear();
  }

  void clear() {
    items.clear();
    businessPartnerIri.value = null;
    businessName.value = '';
    businessDeliveryFee.value = '0.0';
    businessAcceptsCash.value = true;
    market.value = null;
  }

  /// Re-checks every item's live availability against the backend — call
  /// when opening the cart and again right before payment. Removes anything
  /// sold out/expired/deleted and clamps quantity/weight down if stock
  /// dropped, so a stale snapshot never reaches checkout. Safe to call on an
  /// empty cart (no-op).
  Future<CartRevalidationResult> revalidateAll() async {
    if (items.isEmpty) {
      return const CartRevalidationResult(
        removedTitles: [],
        adjustedTitles: [],
      );
    }

    isRevalidating.value = true;
    final removed = <String>[];
    final adjusted = <String>[];
    final kept = <CartItem>[];

    try {
      for (final item in items) {
        final availability = await item.checkAvailability();
        if (!availability.isAvailable) {
          removed.add(item.title);
          continue;
        }

        if (availability.unitPrice != null) {
          item.unitPrice = availability.unitPrice!;
        }
        if (availability.maxQuantity != null) {
          item.maxQuantity = availability.maxQuantity!;
        }
        if (availability.maxWeightKg != null) {
          item.maxWeightKg = availability.maxWeightKg!;
        }

        if (item.isWeightBased) {
          if (item.weightKg > item.maxWeightKg) {
            item.weightKg = item.maxWeightKg;
            adjusted.add(item.title);
          }
        } else {
          final maxQty = item.maxQuantity.toInt();
          if (item.quantity > maxQty) {
            item.quantity = maxQty < 1 ? 1 : maxQty;
            adjusted.add(item.title);
          }
        }
        kept.add(item);
      }

      items
        ..clear()
        ..addAll(kept);
      if (items.isEmpty) clear();
    } finally {
      isRevalidating.value = false;
    }

    return CartRevalidationResult(
      removedTitles: removed,
      adjustedTitles: adjusted,
    );
  }
}
