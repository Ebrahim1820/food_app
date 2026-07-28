import 'package:get/get.dart';

abstract class CustomerFavoritesStrings {
  static String get searchHint => 'custFav_searchHint'.tr;
  static String get sortAlphabetical => 'custFav_sortAlphabetical'.tr;
  static String get sortPrice => 'custFav_sortPrice'.tr;
  static String get sortPriceLowHigh => 'custFav_sortPriceLowHigh'.tr;
  static String get sortPriceHighLow => 'custFav_sortPriceHighLow'.tr;
  static String get filterCategoryDefault => 'custFav_filterCategoryDefault'.tr;
  static String get emptyTitle => 'custFav_emptyTitle'.tr;
  static String get emptySubtitle => 'custFav_emptySubtitle'.tr;
  static String get filteredEmptyTitle => 'custFav_filteredEmptyTitle'.tr;
  static String get filteredEmptySubtitle => 'custFav_filteredEmptySubtitle'.tr;
  static String get browseOffersButton => 'custFav_browseOffersButton'.tr;
  static String get clearFiltersButton => 'custFav_clearFiltersButton'.tr;
  static String get cannotAddSoldOut => 'custFav_cannotAddSoldOut'.tr;

  static String justBackInStock(String name) =>
      'custFav_justBackInStock'.trParams({'name': name});

  static String get backInStockBadge => 'custFav_backInStockBadge'.tr;
  static String get toggleError => 'custFav_toggleError'.tr;
}
