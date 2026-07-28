import 'package:get/get.dart';

abstract class FoodOfferStrings {
  static String get title => 'foodOffer_title'.tr;
  static String get noOffers => 'foodOffer_noOffers'.tr;
  static String get available => 'foodOffer_available'.tr;
  static String get price => 'foodOffer_price'.tr;
  static String get startTime => 'foodOffer_startTime'.tr;
  static String get endTime => 'foodOffer_endTime'.tr;

  static String get previewEdit => 'foodOffer_previewEdit'.tr;
  static String get previewPublish => 'foodOffer_previewPublish'.tr;
  static String get previewPublishing => 'foodOffer_previewPublishing'.tr;
  static String get previewPublishError => 'foodOffer_previewPublishError'.tr;
}

abstract class FoodCategories {
  static String get all => 'cat_all'.tr;
  static String get fastFood => 'cat_fastFood'.tr;
  static String get pizza => 'cat_pizza'.tr;
  static String get bakery => 'cat_bakery'.tr;
  static String get restaurant => 'cat_restaurant'.tr;
  static String get supermarket => 'cat_supermarket'.tr;
  static String get cafe => 'cat_cafe'.tr;
  static String get meals => 'cat_meals'.tr;
  static String get breadPastries => 'cat_breadPastries'.tr;
  static String get fruitsVegetables => 'cat_fruitsVegetables'.tr;
  static String get groceries => 'cat_groceries'.tr;
  static String get hotDrinks => 'cat_hotDrinks'.tr;
  static String get cheeseDairy => 'cat_cheeseDairy'.tr;
  static String get butcher => 'cat_butcher'.tr;
  static String get fish => 'cat_fish'.tr;
  static String get deliCatering => 'cat_deliCatering'.tr;
  static String get flowers => 'cat_flowers'.tr;
  static String get salads => 'cat_salads'.tr;

  /// Translates an API category value to its display label.
  /// Handles both current and legacy values for backward compatibility.
  static String label(String cat) => switch (cat.toLowerCase()) {
    'fast_food' || 'fastfood' => fastFood,
    'pizza' => pizza,
    'bakery' => bakery,
    'restaurant' => restaurant,
    'supermarket' => supermarket,
    'cafe' || 'caffe' => cafe,
    'meals' || 'meal' => meals,
    'bread_pastries' => breadPastries,
    'fruits_vegetables' || 'vegetables' || 'fruit' => fruitsVegetables,
    'groceries' || 'grocery' => groceries,
    'hot_drinks' || 'drinks' => hotDrinks,
    'cheese_dairy' => cheeseDairy,
    'butcher' => butcher,
    'fish' => fish,
    'deli_catering' => deliCatering,
    'flowers' || 'florist' => flowers,
    'salads' || 'salad' || 'dessert' => salads,
    _ => all,
  };

  static List<String> get values => [
    all,
    fastFood,
    pizza,
    bakery,
    restaurant,
    supermarket,
    cafe,
    meals,
    breadPastries,
    fruitsVegetables,
    groceries,
    hotDrinks,
    cheeseDairy,
    butcher,
    fish,
    deliCatering,
    flowers,
    salads,
  ];
}

abstract class SortLabels {
  static String get newest => 'sort_newest'.tr;
  static String get priceLowHigh => 'sort_priceLowHigh'.tr;
  static String get priceHighLow => 'sort_priceHighLow'.tr;
  static String get popular => 'sort_popular'.tr;
}
