import 'package:get/get.dart';

abstract class CustomerProfileStrings {
  // ── Profile tab overview ──────────────────────────────────────────────────
  static String get editProfileButton => 'custProfile_editProfileButton'.tr;
  static String get logoutButton => 'custProfile_logoutButton'.tr;
  static String get myAccount => 'custProfile_myAccount'.tr;
  static String get memberSince => 'custProfile_memberSince'.tr;
  static String get quickActions => 'custProfile_quickActions'.tr;

  // ── Stats ─────────────────────────────────────────────────────────────────
  static String get statOrders => 'custProfile_statOrders'.tr;
  static String get statFavorites => 'custProfile_statFavorites'.tr;
  static String get statSaved => 'custProfile_statSaved'.tr;

  // ── Drawer menu labels ────────────────────────────────────────────────────
  static String get menuAddresses => 'custProfile_menuAddresses'.tr;
  static String get menuFavorites => 'custProfile_menuFavorites'.tr;
  static String get menuPaymentMethods => 'custProfile_menuPaymentMethods'.tr;
  static String get menuSettings => 'custProfile_menuSettings'.tr;
  static String get menuOrders => 'custProfile_menuOrders'.tr;
  static String get menuHelp => 'custProfile_menuHelp'.tr;
  static String get menuAbout => 'custProfile_menuAbout'.tr;

  /// Drawer badge shown only to users who also have business/staff access —
  /// tapping it switches to the business dashboard.
  static String get businessViewBadge => 'custProfile_businessViewBadge'.tr;

  // ── Support section (profile tab) ─────────────────────────────────────────
  static String get supportHelpCenter => 'custProfile_supportHelpCenter'.tr;
  static String get supportAbout => 'custProfile_supportAbout'.tr;

  // ── Action tile subtitles ─────────────────────────────────────────────────
  static String get subEditProfile => 'custProfile_subEditProfile'.tr;
  static String get subAddresses => 'custProfile_subAddresses'.tr;
  static String get subPaymentMethods => 'custProfile_subPaymentMethods'.tr;
  static String get subSettings => 'custProfile_subSettings'.tr;
  static String get subHelp => 'custProfile_subHelp'.tr;
  static String get subAbout => 'custProfile_subAbout'.tr;

  // ── Edit profile ──────────────────────────────────────────────────────────
  static String get editProfileTitle => 'custProfile_editProfileTitle'.tr;
  static String get firstName => 'custProfile_firstName'.tr;
  static String get lastName => 'custProfile_lastName'.tr;
  static String get email => 'custProfile_email'.tr;
  static String get phone => 'custProfile_phone'.tr;
  static String get saveChanges => 'custProfile_saveChanges'.tr;
  static String get profileUpdated => 'custProfile_profileUpdated'.tr;
  static String get saveError => 'custProfile_saveError'.tr;
  static String get saveRetry => 'custProfile_saveRetry'.tr;
  static String get personalInfo => 'custProfile_personalInfo'.tr;
  static String get emailReadOnly => 'custProfile_emailReadOnly'.tr;

  // ── Addresses ─────────────────────────────────────────────────────────────
  static String get addresses => 'custProfile_addresses'.tr;
  static String get addAddress => 'custProfile_addAddress'.tr;
  static String get noAddresses => 'custProfile_noAddresses'.tr;
  static String get noAddressesBody => 'custProfile_noAddressesBody'.tr;
  static String get defaultAddress => 'custProfile_defaultAddress'.tr;
  static String get deleteAddress => 'custProfile_deleteAddress'.tr;
  static String get streetLabel => 'custProfile_streetLabel'.tr;
  static String get cityLabel => 'custProfile_cityLabel'.tr;
  static String get countryLabel => 'custProfile_countryLabel'.tr;
  static String get postalLabel => 'custProfile_postalLabel'.tr;
  static String get addressSaved => 'custProfile_addressSaved'.tr;
  static String get addressDeleted => 'custProfile_addressDeleted'.tr;
  static String get myAddresses => 'custProfile_myAddresses'.tr;
  static String get addNewAddress => 'custProfile_addNewAddress'.tr;
  static String get setAsDefault => 'custProfile_setAsDefault'.tr;
  static String get defaultBadge => 'custProfile_defaultBadge'.tr;
  static String get selected => 'custProfile_selected'.tr;
  static String get addressUpdated => 'custProfile_addressUpdated'.tr;
  static String get labelHome => 'custProfile_labelHome'.tr;
  static String get labelWork => 'custProfile_labelWork'.tr;
  static String get labelOther => 'custProfile_labelOther'.tr;
  static String get street2Label => 'custProfile_street2Label'.tr;
  static String get stateLabel => 'custProfile_stateLabel'.tr;
  static String get countryCodeLabel => 'custProfile_countryCodeLabel'.tr;
  static String get editAddress => 'custProfile_editAddress'.tr;
  static String get deleteAddressTitle => 'custProfile_deleteAddressTitle'.tr;
  static String get deleteAddressBody => 'custProfile_deleteAddressBody'.tr;
  static String get deleteAddressConfirm =>
      'custProfile_deleteAddressConfirm'.tr;
  static String get deleteAddressCancel => 'custProfile_deleteAddressCancel'.tr;
  static String get addressSaveError => 'custProfile_addressSaveError'.tr;
  static String get addressUpdateError => 'custProfile_addressUpdateError'.tr;
  static String get addressDeleteError => 'custProfile_addressDeleteError'.tr;
  static String get addressSetDefaultError =>
      'custProfile_addressSetDefaultError'.tr;

  // ── Payment methods ───────────────────────────────────────────────────────
  static String get paymentMethods => 'custProfile_paymentMethods'.tr;
  static String get addCard => 'custProfile_addCard'.tr;
  static String get noPayments => 'custProfile_noPayments'.tr;
  static String get noPaymentsBody => 'custProfile_noPaymentsBody'.tr;
  static String get defaultCard => 'custProfile_defaultCard'.tr;
  static String get paymentSectionSaved => 'custProfile_paymentSectionSaved'.tr;
  static String get paymentSectionOther => 'custProfile_paymentSectionOther'.tr;
  static String cardEnding(String last4) =>
      'custProfile_cardEnding'.trParams({'last4': last4});
  static String cardExpires(String date) =>
      'custProfile_cardExpires'.trParams({'date': date});

  // ── Settings ──────────────────────────────────────────────────────────────
  static String get settings => 'custProfile_settings'.tr;
  static String get sectionLanguage => 'custProfile_sectionLanguage'.tr;
  static String get languageEnglish => 'custProfile_languageEnglish'.tr;
  static String get languageFarsi => 'custProfile_languageFarsi'.tr;
  static String get sectionNotifications =>
      'custProfile_sectionNotifications'.tr;
  static String get notifPush => 'custProfile_notifPush'.tr;
  static String get notifPushSub => 'custProfile_notifPushSub'.tr;
  static String get notifEmail => 'custProfile_notifEmail'.tr;
  static String get notifEmailSub => 'custProfile_notifEmailSub'.tr;
  static String get notifPromo => 'custProfile_notifPromo'.tr;
  static String get notifPromoSub => 'custProfile_notifPromoSub'.tr;
  static String get sectionPrivacy => 'custProfile_sectionPrivacy'.tr;
  static String get changePassword => 'custProfile_changePassword'.tr;
  static String get changePasswordSub => 'custProfile_changePasswordSub'.tr;
  static String get biometric => 'custProfile_biometric'.tr;
  static String get biometricSub => 'custProfile_biometricSub'.tr;
  static String get deleteAccount => 'custProfile_deleteAccount'.tr;
  static String get deleteAccountSub => 'custProfile_deleteAccountSub'.tr;
  static String get sectionApp => 'custProfile_sectionApp'.tr;
  static String get appVersion => 'custProfile_appVersion'.tr;
  static String get clearCache => 'custProfile_clearCache'.tr;
  static String get clearCacheSub => 'custProfile_clearCacheSub'.tr;
  static String get cacheCleared => 'custProfile_cacheCleared'.tr;
  static String get rateApp => 'custProfile_rateApp'.tr;
  static String get rateAppSub => 'custProfile_rateAppSub'.tr;

  // ── Help & Support ────────────────────────────────────────────────────────
  static String get helpTitle => 'custProfile_helpTitle'.tr;
  static String get helpGetInTouch => 'custProfile_helpGetInTouch'.tr;
  static String get helpLiveChat => 'custProfile_helpLiveChat'.tr;
  static String get helpChatSub => 'custProfile_helpChatSub'.tr;
  static String get helpEmail => 'custProfile_helpEmail'.tr;
  static String get helpEmailSub => 'custProfile_helpEmailSub'.tr;
  static String get helpCall => 'custProfile_helpCall'.tr;
  static String get helpCallSub => 'custProfile_helpCallSub'.tr;
  static String get helpFaq => 'custProfile_helpFaq'.tr;
  static String get helpVisitCentre => 'custProfile_helpVisitCentre'.tr;
  static String get helpCentreSub => 'custProfile_helpCentreSub'.tr;
  static String get helpOpening => 'custProfile_helpOpening'.tr;
  static String get helpOpeningValue => 'custProfile_helpOpeningValue'.tr;
  static String get helpSnackChat => 'custProfile_helpSnackChat'.tr;
  static String get helpSnackEmail => 'custProfile_helpSnackEmail'.tr;
  static String get helpSnackCall => 'custProfile_helpSnackCall'.tr;
  static String get helpSnackCentre => 'custProfile_helpSnackCentre'.tr;

  // ── Live Chat screen ───────────────────────────────────────────────────────
  static String get chatAgentName => 'custProfile_chatAgentName'.tr;
  static String get chatSubtitle => 'custProfile_chatSubtitle'.tr;
  static String get chatOnline => 'custProfile_chatOnline'.tr;
  static String get chatAgentFullName => 'custProfile_chatAgentFullName'.tr;
  static String get chatAgentShort => 'custProfile_chatAgentShort'.tr;
  static String get chatWelcome1 => 'custProfile_chatWelcome1'.tr;
  static String get chatWelcome2 => 'custProfile_chatWelcome2'.tr;
  static String get chatAgentReply => 'custProfile_chatAgentReply'.tr;
  static String get chatQuick1 => 'custProfile_chatQuick1'.tr;
  static String get chatQuick2 => 'custProfile_chatQuick2'.tr;
  static String get chatQuick3 => 'custProfile_chatQuick3'.tr;
  static String get chatQuick4 => 'custProfile_chatQuick4'.tr;
  static String get chatInputHint => 'custProfile_chatInputHint'.tr;

  // ── Email Support screen ───────────────────────────────────────────────────
  static String get emailSupportTitle => 'custProfile_emailSupportTitle'.tr;
  static String get emailSupportSubtitle =>
      'custProfile_emailSupportSubtitle'.tr;
  static String get emailBadge => 'custProfile_emailBadge'.tr;
  static String get emailResponseLabel => 'custProfile_emailResponseLabel'.tr;
  static String get emailResponseShort => 'custProfile_emailResponseShort'.tr;
  static String get emailResponseValue => 'custProfile_emailResponseValue'.tr;
  static String get emailSubjectLabel => 'custProfile_emailSubjectLabel'.tr;
  static String get emailSubjectOrder => 'custProfile_emailSubjectOrder'.tr;
  static String get emailSubjectDelivery =>
      'custProfile_emailSubjectDelivery'.tr;
  static String get emailSubjectPayment => 'custProfile_emailSubjectPayment'.tr;
  static String get emailSubjectGeneral => 'custProfile_emailSubjectGeneral'.tr;
  static String get emailMessageLabel => 'custProfile_emailMessageLabel'.tr;
  static String get emailMessageHint => 'custProfile_emailMessageHint'.tr;
  static String get emailSendBtn => 'custProfile_emailSendBtn'.tr;
  static String get emailPrivacy => 'custProfile_emailPrivacy'.tr;
  static String get emailRequired => 'custProfile_emailRequired'.tr;
  static String get emailRequiredSub => 'custProfile_emailRequiredSub'.tr;
  static String get emailSentTitle => 'custProfile_emailSentTitle'.tr;
  static String get emailSentSub => 'custProfile_emailSentSub'.tr;

  // ── Call Us screen ─────────────────────────────────────────────────────────
  static String get callSupportTitle => 'custProfile_callSupportTitle'.tr;
  static String get callSupportSubtitle => 'custProfile_callSupportSubtitle'.tr;
  static String get callBadge => 'custProfile_callBadge'.tr;
  static String get callHotlineLabel => 'custProfile_callHotlineLabel'.tr;
  static String get callHoldCopy => 'custProfile_callHoldCopy'.tr;
  static String get callNowBtn => 'custProfile_callNowBtn'.tr;
  static String get callbackBtn => 'custProfile_callbackBtn'.tr;
  static String get callCopied => 'custProfile_callCopied'.tr;
  static String get callCopiedSub => 'custProfile_callCopiedSub'.tr;
  static String get callDialing => 'custProfile_callDialing'.tr;
  static String get callbackRequested => 'custProfile_callbackRequested'.tr;
  static String get callbackSub => 'custProfile_callbackSub'.tr;
  static String get callAvailability => 'custProfile_callAvailability'.tr;
  static String get callAlternative => 'custProfile_callAlternative'.tr;
  static String get callMonFri => 'custProfile_callMonFri'.tr;
  static String get callMonFriShort => 'custProfile_callMonFriShort'.tr;
  static String get callMonFriHours => 'custProfile_callMonFriHours'.tr;
  static String get callSat => 'custProfile_callSat'.tr;
  static String get callSatHours => 'custProfile_callSatHours'.tr;
  static String get callSun => 'custProfile_callSun'.tr;
  static String get callSunHours => 'custProfile_callSunHours'.tr;
  static String get callWhatsapp => 'custProfile_callWhatsapp'.tr;
  static String get callSms => 'custProfile_callSms'.tr;
  static String get callOpeningWhatsapp => 'custProfile_callOpeningWhatsapp'.tr;
  static String get callOpeningSms => 'custProfile_callOpeningSms'.tr;

  static List<({String q, String a})> get helpFaqs => [
    (q: 'custProfile_helpFaq0Q'.tr, a: 'custProfile_helpFaq0A'.tr),
    (q: 'custProfile_helpFaq1Q'.tr, a: 'custProfile_helpFaq1A'.tr),
    (q: 'custProfile_helpFaq2Q'.tr, a: 'custProfile_helpFaq2A'.tr),
    (q: 'custProfile_helpFaq3Q'.tr, a: 'custProfile_helpFaq3A'.tr),
    (q: 'custProfile_helpFaq4Q'.tr, a: 'custProfile_helpFaq4A'.tr),
    (q: 'custProfile_helpFaq5Q'.tr, a: 'custProfile_helpFaq5A'.tr),
  ];

  // ── About ─────────────────────────────────────────────────────────────────
  static String get aboutTitle => 'custProfile_aboutTitle'.tr;
  static String get aboutTagline => 'custProfile_aboutTagline'.tr;
  static String get aboutMissionTitle => 'custProfile_aboutMissionTitle'.tr;
  static String get aboutMissionText => 'custProfile_aboutMissionText'.tr;
  static String get aboutPrivacy => 'custProfile_aboutPrivacy'.tr;
  static String get aboutTerms => 'custProfile_aboutTerms'.tr;
  static String get aboutLicenses => 'custProfile_aboutLicenses'.tr;
  static String get aboutMadeWith => 'custProfile_aboutMadeWith'.tr;
  static String get aboutFollowUs => 'custProfile_aboutFollowUs'.tr;
  static String get aboutVersion => 'custProfile_aboutVersion'.tr;
  static String get aboutLegal => 'custProfile_aboutLegal'.tr;
  static String get aboutSocial => 'custProfile_aboutSocial'.tr;
}
