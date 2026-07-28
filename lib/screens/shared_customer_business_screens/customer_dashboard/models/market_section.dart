/// One horizontal row of items on a customer discovery screen, grouped by
/// category. A market's own section model (e.g. FoodSectionModel) should
/// `implement MarketSection<TItem>` so its existing RxList can be passed
/// straight into [CustomerDiscoveryScreen] without any copying/mapping —
/// Dart's covariant generics make `RxList<FoodSectionModel>` assignable
/// wherever `RxList<MarketSection<FoodOfferModel>>` is expected.
abstract class MarketSection<T> {
  String get category;
  String get label;
  int get total;
  bool get hasMore;
  List<T> get items;
}
