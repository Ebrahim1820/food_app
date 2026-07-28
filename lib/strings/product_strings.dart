import 'package:get/get.dart';

/// Typed translation-key accessors for the generic Product feature — same
/// shape as `lib/strings/app_strings.dart`'s per-feature classes. No widget
/// under `lib/src/shared/customer_business_logic/` should contain an inline string literal
/// for user-facing text; add a getter here instead.
abstract class ProductStrings {
  static String get loadError => 'product_loadError'.tr;
  static String get searchHint => 'product_searchHint'.tr;
  static String get seeAll => 'common_seeAll'.tr;

  // ── Product detail screen ─────────────────────────────────────────────────
  static String get aboutTitle => 'product_aboutTitle'.tr;
  static String get buyNow => 'product_buyNow'.tr;
  static String get outOfStock => 'product_outOfStock'.tr;

  // Reuses the same generic keys the Food detail screen already translates
  // (wording isn't food-specific), so no new strings were needed for these.
  static String stockLeft(int qty) =>
      'custHomeCard_stockLeft'.trParams({'qty': '$qty'});
  static String get kgAvailable => 'offer_kgAvailable'.tr;

  // ── Favorites screen ───────────────────────────────────────────────────────
  // Sort/filter/search chrome reuses Food's `custFav_*` keys directly — that
  // wording is already market-neutral ("Price", "A → Z", "No favorites yet",
  // ...). Only the two genuinely Food-flavored strings ("...favourite
  // meals...", "Browse offers") got their own Product-scoped keys below.
  static String get favoritesSearchHint => 'custFav_searchHint'.tr;
  static String get favoritesSortAlphabetical => 'custFav_sortAlphabetical'.tr;
  static String get favoritesSortPrice => 'custFav_sortPrice'.tr;
  static String get favoritesSortPriceLowHigh =>
      'custFav_sortPriceLowHigh'.tr;
  static String get favoritesSortPriceHighLow =>
      'custFav_sortPriceHighLow'.tr;
  static String get favoritesEmptyTitle => 'custFav_emptyTitle'.tr;
  static String get favoritesFilteredEmptyTitle =>
      'custFav_filteredEmptyTitle'.tr;
  static String get favoritesFilteredEmptySubtitle =>
      'custFav_filteredEmptySubtitle'.tr;
  static String get favoritesClearFiltersButton =>
      'custFav_clearFiltersButton'.tr;

  static String get favoritesEmptySubtitle =>
      'product_favoritesEmptySubtitle'.tr;
  static String get favoritesBrowseButton => 'product_favoritesBrowseButton'.tr;

  // ── Order list screen ───────────────────────────────────────────────────────
  // Every one of these reuses Food's `custOrder_*` keys directly — the
  // wording is already market-neutral ("My Orders", "Search by order ID or
  // store…", "Try a different status or date range", ...), so no new
  // translations were needed.
  static String get ordersPageTitle => 'custOrder_pageTitle'.tr;
  static String get ordersSearchHint => 'custOrder_searchHint'.tr;
  static String get ordersSortNewest => 'custOrder_sortNewest'.tr;
  static String get ordersSortOldest => 'custOrder_sortOldest'.tr;
  static String get ordersSortPrice => 'custOrder_sortPrice'.tr;
  static String get ordersSortPriceLowHigh => 'custOrder_sortPriceLowHigh'.tr;
  static String get ordersSortPriceHighLow => 'custOrder_sortPriceHighLow'.tr;
  static String get ordersFilterToday => 'custOrder_filterToday'.tr;
  static String get ordersFilterThisWeek => 'custOrder_filterThisWeek'.tr;
  static String get ordersSectionActive => 'custOrder_sectionActive'.tr;
  static String get ordersSectionDone => 'custOrder_sectionDone'.tr;
  static String get ordersEmptyTitle => 'custOrder_emptyTitle'.tr;
  static String get ordersEmptySubtitle => 'custOrder_emptySubtitle'.tr;
  static String get ordersFilteredEmptyTitle => 'custOrder_filteredEmptyTitle'.tr;
  static String get ordersFilteredEmptySubtitle =>
      'custOrder_filteredEmptySubtitle'.tr;
  static String get ordersClearFiltersButton =>
      'custOrder_clearFiltersButton'.tr;
  static String get ordersTryAgain => 'custOrder_tryAgain'.tr;
}

/// Business-side (create/manage listings) translation keys.
abstract class BusinessProductStrings {
  static String get myProductsTitle => 'productBiz_myProductsTitle'.tr;
  static String get newProductButton => 'productBiz_newProductButton'.tr;
  static String get searchHint => 'productBiz_searchHint'.tr;
  static String get sortOldestFirst => 'productBiz_sortOldestFirst'.tr;
  static String get deleteTooltip => 'productBiz_deleteTooltip'.tr;
  static String get noProductsFiltered => 'productBiz_noProductsFiltered'.tr;
  static String get noProductsYet => 'productBiz_noProductsYet'.tr;
  static String get filteredEmptyHint => 'productBiz_filteredEmptyHint'.tr;
  static String get emptyHint => 'productBiz_emptyHint'.tr;
  static String get clearFilters => 'productBiz_clearFilters'.tr;
  static String get addFirstProduct => 'productBiz_addFirstProduct'.tr;
  static String get notReadyTitle => 'productBiz_notReadyTitle'.tr;
  static String get notReadyBody => 'productBiz_notReadyBody'.tr;
  static String get errorSnackTitle => 'productBiz_errorSnackTitle'.tr;
  static String get couldNotDelete => 'productBiz_couldNotDelete'.tr;
  static String get retryButton => 'productBiz_retryButton'.tr;
  static String productCount(int count) =>
      'productBiz_productCount'.trParams({'count': '$count'});
  static String quantityLeft(int left, int total) =>
      'productBiz_quantityLeft'.trParams({'left': '$left', 'total': '$total'});

  static String get createAppBarTitle => 'productCreate_appBarTitle'.tr;
  static String get labelItemName => 'productCreate_labelItemName'.tr;
  static String get nameHint => 'productCreate_nameHint'.tr;
  static String get labelDescription => 'productCreate_labelDescription'.tr;
  static String get descriptionHint => 'productCreate_descriptionHint'.tr;
  static String get labelCategory => 'productCreate_labelCategory'.tr;
  static String get labelSellByWeight => 'productCreate_labelSellByWeight'.tr;
  static String get hintWeightExample => 'productCreate_hintWeightExample'.tr;
  static String get hintPortionExample =>
      'productCreate_hintPortionExample'.tr;
  static String get labelOriginalPrice => 'productCreate_labelOriginalPrice'.tr;
  static String get labelDealPrice => 'productCreate_labelDealPrice'.tr;
  static String get labelPricePerKg => 'productCreate_labelPricePerKg'.tr;
  static String get labelOrigPricePerKg =>
      'productCreate_labelOrigPricePerKg'.tr;
  static String get labelWeightAvailable =>
      'productCreate_labelWeightAvailable'.tr;
  static String get labelMinOrder => 'productCreate_labelMinOrder'.tr;
  static String get labelQuantity => 'productCreate_labelQuantity'.tr;
  static String get addPhoto => 'productCreate_addPhoto'.tr;
  static String get publishButton => 'productCreate_publishButton'.tr;
  static String get validatorNameRequired =>
      'productCreate_validatorNameRequired'.tr;
  static String get validatorRequired => 'productCreate_validatorRequired'.tr;
  static String get validatorInvalidAmount =>
      'productCreate_validatorInvalidAmount'.tr;
  static String get validatorCategoryRequired =>
      'productCreate_validatorCategoryRequired'.tr;
  static String get snackSuccessTitle => 'productCreate_snackSuccessTitle'.tr;
  static String get snackErrorTitle => 'productCreate_snackErrorTitle'.tr;
  static String get snackPublished => 'productCreate_snackPublished'.tr;
  static String get snackCouldNotSave => 'productCreate_snackCouldNotSave'.tr;

  static String networkError(String code) =>
      'productBiz_networkError'.trParams({'code': code});
  static String unexpectedError(String error) =>
      'productBiz_unexpectedError'.trParams({'error': error});
  static String get loadError => 'productBiz_loadError'.tr;
  static String get categoryRequired => 'productBiz_categoryRequired'.tr;
}
