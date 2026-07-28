/// Result of re-checking one [CartItem] against the backend — see
/// [CartItem.checkAvailability].
class CartItemAvailability {
  const CartItemAvailability({
    required this.isAvailable,
    this.unitPrice,
    this.maxQuantity,
    this.maxWeightKg,
  });

  /// False when the offer/product is sold out, past its window, or no
  /// longer exists at all — [CartController.revalidateAll] removes the item
  /// entirely in that case.
  final bool isAvailable;

  /// Null means "unchanged, keep whatever the item already has" — a market
  /// wiring only needs to pass these when the fresh fetch actually differs.
  final double? unitPrice;
  final double? maxQuantity;
  final double? maxWeightKg;
}

/// One line in the per-business cart — market-agnostic (no FoodOfferModel or
/// ProductModel dependency), so [CartController]/[CartScreen] never need to
/// know which market an item came from. A market's own product-detail
/// wiring builds this from its own model, the same way [OrderLineItem] is
/// built for the payment step.
class CartItem {
  CartItem({
    required this.itemIri,
    required this.payloadKey,
    required this.title,
    required this.checkAvailability,
    this.imageUrl,
    required this.unitPrice,
    required this.isWeightBased,
    this.maxQuantity = 999,
    this.maxWeightKg = 999,
    this.minWeightKg = 0.1,
    this.quantity = 1,
    double? weightKg,
  }) : weightKg = weightKg ?? minWeightKg;

  /// e.g. `/api/food-offers/12` or `/api/products/7`.
  final String itemIri;

  /// The exact key the backend expects this item's IRI under —
  /// `'foodOffer'` or `'product'`.
  final String payloadKey;

  final String title;
  final String? imageUrl;

  /// Re-fetches this item's live availability from the backend — built by
  /// whichever market wiring created this item (it captures just the IRI,
  /// not the original model, so it always reflects the *current* backend
  /// state whenever it's actually called, however long the item has been
  /// sitting in the cart). Called by [CartController.revalidateAll].
  final Future<CartItemAvailability> Function() checkAvailability;

  /// Price per unit, or per kg when [isWeightBased]. Mutable — a
  /// revalidation can refresh it if the backend price changed.
  double unitPrice;
  final bool isWeightBased;

  /// Available stock — caps how far [quantity] can be incremented. Mutable,
  /// refreshed by revalidation.
  double maxQuantity;

  /// Available weight (kg) — caps [weightKg]. Mutable, refreshed by
  /// revalidation.
  double maxWeightKg;

  /// Minimum order weight (kg) for weight-based items.
  final double minWeightKg;

  int quantity;
  double weightKg;

  double get lineTotal =>
      isWeightBased ? unitPrice * weightKg : unitPrice * quantity;
}
