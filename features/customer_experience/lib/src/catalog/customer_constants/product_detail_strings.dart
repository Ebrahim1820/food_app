import 'package:get/get.dart';

abstract class ProductDetailStrings {
  static String get location => 'detail_location'.tr;
  static String get moreInfo => 'detail_moreInfo'.tr;
  static String get getDirections => 'detail_getDirections'.tr;
  static String get mapUnavailable => 'detail_mapUnavailable'.tr;
  static String get tapViewMap => 'detail_tapViewMap'.tr;
  static String get addressNotAvailable => 'detail_addressNotAvailable'.tr;
  static String get businessRating => 'detail_businessRating'.tr;
  static String get today => 'detail_today'.tr;
  static String get tomorrow => 'detail_tomorrow'.tr;
  static String get weightBased => 'detail_weightBased'.tr;
  static String get noDescription => 'detail_noDescription'.tr;
  static String get reserve => 'detail_reserve'.tr;
  static String get offerEnded => 'detail_offerEnded'.tr;
  static String get restaurantClosed => 'detail_restaurantClosed'.tr;
  static String get restaurantClosedBody => 'detail_restaurantClosedBody'.tr;
  static String get gotIt => 'detail_gotIt'.tr;

  static String bagLabel(String category) => switch (category.toLowerCase()) {
    'bakery' || 'bread_pastries' => 'detail_bagBakery'.tr,
    'fast_food' ||
    'fastfood' ||
    'pizza' ||
    'restaurant' ||
    'meals' ||
    'meal' ||
    'deli_catering' => 'detail_bagMeal'.tr,
    'groceries' ||
    'grocery' ||
    'supermarket' ||
    'cheese_dairy' ||
    'butcher' ||
    'fish' => 'detail_bagGrocery'.tr,
    'fruits_vegetables' || 'vegetables' || 'fruit' => 'detail_bagFruit'.tr,
    'hot_drinks' || 'drinks' || 'cafe' || 'caffe' => 'detail_bagDrinks'.tr,
    _ => 'detail_bagDefault'.tr,
  };

  static String aboutTitle(String category) =>
      'detail_aboutTitle'.trParams({'bag': bagLabel(category)});

  static String savePct(int pct) =>
      'detail_savePct'.trParams({'pct': pct.toString()});

  static String origValueItem(String orig, String cur) =>
      'detail_origValueItem'.trParams({'orig': orig, 'cur': cur});

  static String origValueKg(String orig, String cur) =>
      'detail_origValueKg'.trParams({'orig': orig, 'cur': cur});

  static String pricePerKg(String min) =>
      'detail_pricePerKg'.trParams({'min': min});

  static String get pickUp => 'detail_pickUp'.tr;
  static String get pickupWindow => 'detail_pickupWindow'.tr;
  static String get from => 'detail_from'.tr;
  static String get until => 'detail_until'.tr;
  static String get distance => 'detail_distance'.tr;

  static String weekdayShort(int weekday) => [
    'detail_mon',
    'detail_tue',
    'detail_wed',
    'detail_thu',
    'detail_fri',
    'detail_sat',
    'detail_sun',
  ][weekday - 1].tr;

  static String monthShort(int month) => [
    'detail_jan',
    'detail_feb',
    'detail_mar',
    'detail_apr',
    'detail_may',
    'detail_jun',
    'detail_jul',
    'detail_aug',
    'detail_sep',
    'detail_oct',
    'detail_nov',
    'detail_dec',
  ][month - 1].tr;
}
