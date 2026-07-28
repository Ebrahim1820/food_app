import 'package:get/get.dart';

abstract class CustomerHomeStrings {
  static String get searchHint => 'custHome_searchHint'.tr;
  static String get seeAll => 'custHome_seeAll'.tr;
  static String get categoryAll => 'custHome_categoryAll'.tr;
  static const fallbackCategoryEmoji = '🍽';
  static String get noOffersTitle => 'custHome_noOffersTitle'.tr;
  static String get noOffersSubtitle => 'custHome_noOffersSubtitle'.tr;
  static String get noSearchResultsTitle => 'custHome_noSearchResultsTitle'.tr;
  static String get noSearchResultsSubtitle =>
      'custHome_noSearchResultsSubtitle'.tr;
}

abstract class CustomerOfferCardStrings {
  static String get available => 'custOfferCard_available'.tr;
  static String get ended => 'custOfferCard_ended'.tr;
  static String get orderNow => 'custOfferCard_orderNow'.tr;
  static String get unavailable => 'custOfferCard_unavailable'.tr;
  static String get unknownBusiness => 'custOfferCard_unknownBusiness'.tr;
  static String get noAddress => 'custOfferCard_noAddress'.tr;
  static String get noCity => 'custOfferCard_noCity'.tr;
  static String get businessClosed => 'custOfferCard_businessClosed'.tr;
  static String get notifyBadge => 'custOfferCard_notifyBadge'.tr;
  static String get notifyMeButton => 'custOfferCard_notifyMeButton'.tr;

  static String saveBadge(int pct) =>
      'custOfferCard_saveBadge'.trParams({'pct': '$pct'});
}

abstract class BusinessInactiveDialogStrings {
  static String get title => 'bizInactive_title'.tr;
  static String get body => 'bizInactive_body'.tr;
  static String get closeButton => 'bizInactive_closeButton'.tr;
}

abstract class CustomerCategoryFilterStrings {
  static String get emptyTitle => 'custCatFilter_emptyTitle'.tr;
  static String get emptySubtitle => 'custCatFilter_emptySubtitle'.tr;
  static String get showAllButton => 'custCatFilter_showAll'.tr;
}

abstract class CustomerHomeOfferCardStrings {
  static String get ended => 'custHomeCard_ended'.tr;

  static String saveBadge(int pct) =>
      'custHomeCard_saveBadge'.trParams({'pct': '$pct'});
  static String stockLeft(int qty) =>
      'custHomeCard_stockLeft'.trParams({'qty': '$qty'});
}
