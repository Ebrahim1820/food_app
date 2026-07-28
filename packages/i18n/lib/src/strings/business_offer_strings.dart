import 'package:get/get.dart';
import '../currency_formatter.dart';

abstract class BusinessOfferCreateStrings {
  static String get appBarTitle => 'bizCreate_appBarTitle'.tr;
  static String get labelItemName => 'bizCreate_labelItemName'.tr;
  static String get labelSellByWeight => 'bizCreate_labelSellByWeight'.tr;
  static String get hintWeightExample => 'bizCreate_hintWeightExample'.tr;
  static String get hintPortionExample => 'bizCreate_hintPortionExample'.tr;
  static String get labelPricePerKg => 'bizCreate_labelPricePerKg'.tr;
  static String get labelOrigPricePerKg => 'bizCreate_labelOrigPricePerKg'.tr;
  static String get labelWeightAvailable => 'bizCreate_labelWeightAvailable'.tr;
  static String get labelMinOrder => 'bizCreate_labelMinOrder'.tr;
  static String get labelQuantity => 'bizCreate_labelQuantity'.tr;
  static String get labelPickupWindow => 'bizCreate_labelPickupWindow'.tr;
  static String get publishButton => 'bizCreate_publishButton'.tr;
  static String get snackPublished => 'bizCreate_snackPublished'.tr;
  static String get snackCouldNotSave => 'bizCreate_snackCouldNotSave'.tr;
  static String get addPhoto => 'bizCreate_addPhoto'.tr;
  // Reuse bizEdit_* keys that are identical in meaning
  static String get labelDescription => 'bizEdit_sectionDescription'.tr;
  static String get labelCategory => 'bizEdit_sectionCategory'.tr;
  static String get nameHint => 'bizEdit_nameHint'.tr;
  static String get descriptionHint => 'bizEdit_descriptionHint'.tr;
  static String get labelOriginalPrice => 'bizEdit_originalPriceLabel'.tr;
  static String get labelDealPrice => 'bizEdit_dealPriceLabel'.tr;
  static String get pickupStartHint => 'bizEdit_pickupStartHint'.tr;
  static String get pickupEndHint => 'bizEdit_pickupEndHint'.tr;
  static String get validatorNameRequired => 'bizEdit_validatorNameRequired'.tr;
  static String get validatorRequired => 'bizEdit_validatorRequired'.tr;
  static String get validatorInvalidAmount =>
      'bizEdit_validatorInvalidAmount'.tr;
  static String get validatorBelowOriginal =>
      'bizEdit_validatorBelowOriginal'.tr;
  static String get snackErrorTitle => 'bizEdit_snackErrorTitle'.tr;
  static String get snackSuccessTitle => 'bizEdit_snackDoneTitle'.tr;
}

abstract class OfferStatusLabels {
  static String get active => 'offerStatus_active'.tr;
  static String get inactive => 'offerStatus_inactive'.tr;
  static String get cancelled => 'offerStatus_cancelled'.tr;
  static String get soldOut => 'offerStatus_soldOut'.tr;
  static String get expired => 'offerStatus_expired'.tr;
  static String get scheduled => 'offerStatus_scheduled'.tr;
  static String get hidden => 'offerStatus_hidden'.tr;
}

abstract class BusinessOfferMenuStrings {
  static String get searchHint => 'bizMenu_searchHint'.tr;
  static String get sortOldestFirst => 'bizMenu_sortOldestFirst'.tr;
  static String get newOfferButton => 'bizMenu_newOfferButton'.tr;
  static String get deleteTooltip => 'bizMenu_deleteTooltip'.tr;
  static String get noOffersFiltered => 'bizMenu_noOffersFiltered'.tr;
  static String get noOffersYet => 'bizMenu_noOffersYet'.tr;
  static String get filteredEmptyHint => 'bizMenu_filteredEmptyHint'.tr;
  static String get emptyHint => 'bizMenu_emptyHint'.tr;
  static String get clearFilters => 'bizMenu_clearFilters'.tr;
  static String get addFirstOffer => 'bizMenu_addFirstOffer'.tr;
  static String get notReadyTitle => 'bizMenu_notReadyTitle'.tr;
  static String get notReadyBody => 'bizMenu_notReadyBody'.tr;
  static String get errorSnackTitle => 'bizMenu_errorSnackTitle'.tr;
  static String get couldNotDelete => 'bizMenu_couldNotDelete'.tr;
  static String get retryButton => 'bizMenu_retryButton'.tr;

  static String offerCount(int count) =>
      'bizMenu_offerCount'.trParams({'count': '$count'});
  static String quantityLeft(int left, int total) =>
      'bizMenu_quantityLeft'.trParams({'left': '$left', 'total': '$total'});
}

abstract class BusinessOfferEditStrings {
  static String get appBarTitle => 'bizEdit_appBarTitle'.tr;
  static String get deleteTooltip => 'bizEdit_deleteTooltip'.tr;
  static String get sectionPhotos => 'bizEdit_sectionPhotos'.tr;
  static String get sectionStatus => 'bizEdit_sectionStatus'.tr;
  static String get sectionName => 'bizEdit_sectionName'.tr;
  static String get sectionDescription => 'bizEdit_sectionDescription'.tr;
  static String get sectionCategory => 'bizEdit_sectionCategory'.tr;
  static String get sectionPricing => 'bizEdit_sectionPricing'.tr;
  static String get sectionQuantity => 'bizEdit_sectionQuantity'.tr;
  static String get sectionPickup => 'bizEdit_sectionPickup'.tr;
  static String get nameHint => 'bizEdit_nameHint'.tr;
  static String get descriptionHint => 'bizEdit_descriptionHint'.tr;
  static String get originalPriceLabel => 'bizEdit_originalPriceLabel'.tr;
  static String get dealPriceLabel => 'bizEdit_dealPriceLabel'.tr;
  static String get pickupStartHint => 'bizEdit_pickupStartHint'.tr;
  static String get pickupEndHint => 'bizEdit_pickupEndHint'.tr;
  static String get validatorNameRequired => 'bizEdit_validatorNameRequired'.tr;
  static String get validatorRequired => 'bizEdit_validatorRequired'.tr;
  static String get validatorInvalidAmount =>
      'bizEdit_validatorInvalidAmount'.tr;
  static String get validatorBelowOriginal =>
      'bizEdit_validatorBelowOriginal'.tr;
  static String get validatorPickupOrder => 'bizEdit_validatorPickupOrder'.tr;
  static String get imageSourceCamera => 'bizEdit_imageSourceCamera'.tr;
  static String get imageSourceGallery => 'bizEdit_imageSourceGallery'.tr;
  static String get addPhotoButton => 'bizEdit_addPhotoButton'.tr;
  static String get snackDoneTitle => 'bizEdit_snackDoneTitle'.tr;
  static String get snackErrorTitle => 'bizEdit_snackErrorTitle'.tr;
  static String get snackCameraUnavailableTitle =>
      'bizEdit_snackCameraUnavailableTitle'.tr;
  static String get snackCameraUnavailableBody =>
      'bizEdit_snackCameraUnavailableBody'.tr;
  static String get snackUploadFailedTitle =>
      'bizEdit_snackUploadFailedTitle'.tr;
  static String get snackPhotoAddedTitle => 'bizEdit_snackPhotoAddedTitle'.tr;
  static String get snackPhotoAddedBody => 'bizEdit_snackPhotoAddedBody'.tr;
  static String get snackOfferUpdated => 'bizEdit_snackOfferUpdated'.tr;
  static String get snackOfferDeleted => 'bizEdit_snackOfferDeleted'.tr;
  static String get snackCouldNotDelete => 'bizEdit_snackCouldNotDelete'.tr;
  static String get snackCouldNotSave => 'bizEdit_snackCouldNotSave'.tr;
  static String get saveButton => 'bizEdit_saveButton'.tr;

  static String discountBadge(int percent) => 'bizEdit_discountBadge'.trParams({
    'percent': CurrencyFormatter.localizeDigits('$percent'),
  });
}

abstract class BusinessOfferDetailStrings {
  static String get appBarTitle => 'bizDetail_appBarTitle'.tr;
  static String get editAction => 'bizDetail_editAction'.tr;
  static String get pickupWindowLabel => 'bizDetail_pickupWindowLabel'.tr;
  static String get quantityLabel => 'bizDetail_quantityLabel'.tr;
  static String get editButton => 'bizDetail_editButton'.tr;
  static String get cancelButton => 'bizDetail_cancelButton'.tr;
  static String get snackErrorTitle => 'bizDetail_snackErrorTitle'.tr;
  static String get snackAlreadyCancelledTitle =>
      'bizDetail_snackAlreadyCancelledTitle'.tr;
  static String get snackAlreadyCancelledBody =>
      'bizDetail_snackAlreadyCancelledBody'.tr;
  static String get snackOfferCancelledTitle =>
      'bizDetail_snackOfferCancelledTitle'.tr;
  static String get snackOfferCancelledBody =>
      'bizDetail_snackOfferCancelledBody'.tr;
  static String get snackCouldNotCancel => 'bizDetail_snackCouldNotCancel'.tr;

  static String quantityRemaining(int available, int total) =>
      'bizDetail_quantityRemaining'.trParams({
        'available': '$available',
        'total': '$total',
      });
  static String savePct(int pct) =>
      'bizDetail_savePct'.trParams({'pct': '$pct'});
}

abstract class BusinessOfferDialogStrings {
  static String get deleteTitle => 'bizDialog_deleteTitle'.tr;
  static String get deleteBody => 'bizDialog_deleteBody'.tr;
  static String get deleteConfirmLabel => 'bizDialog_deleteConfirmLabel'.tr;
  static String get deleteCancelLabel => 'bizDialog_deleteCancelLabel'.tr;
  static String get cancelTitle => 'bizDialog_cancelTitle'.tr;
  static String get cancelBody => 'bizDialog_cancelBody'.tr;
  static String get cancelConfirmLabel => 'bizDialog_cancelConfirmLabel'.tr;
  static String get cancelCancelLabel => 'bizDialog_cancelCancelLabel'.tr;

  static String offerSubtitle(String title) =>
      'bizDialog_offerSubtitle'.trParams({'title': title});
}

abstract class PickupPickerStrings {
  static String get title => 'pickupPicker_title'.tr;
  static String get tabStart => 'pickupPicker_tabStart'.tr;
  static String get tabEnd => 'pickupPicker_tabEnd'.tr;
  static String get notSet => 'pickupPicker_notSet'.tr;
  static String get placeholder => 'pickupPicker_placeholder'.tr;
  static String get confirmReady => 'pickupPicker_confirmReady'.tr;
  static String get confirmPending => 'pickupPicker_confirmPending'.tr;
  static String get timeStart => 'pickupPicker_timeStart'.tr;
  static String get timeEnd => 'pickupPicker_timeEnd'.tr;
}
