import 'package:i18n/i18n.dart';
import 'package:get/get.dart';

// ── Security ──────────────────────────────────────────────────────────────────
abstract class BusinessSecurityStrings {
  static String get appBarTitle => 'bizSecurity_appBarTitle'.tr;
  static String get sectionPassword => 'bizSecurity_sectionPassword'.tr;
  static String get changePasswordTitle => 'bizSecurity_changePasswordTitle'.tr;
  static String get changePasswordSubtitle =>
      'bizSecurity_changePasswordSubtitle'.tr;
  static String get section2fa => 'bizSecurity_section2fa'.tr;
  static String get twoFaTitle => 'bizSecurity_twoFaTitle'.tr;
  static String get twoFaActiveSubtitle => 'bizSecurity_twoFaActiveSubtitle'.tr;
  static String get twoFaOffSubtitle => 'bizSecurity_twoFaOffSubtitle'.tr;
  static String get twoFaEnabledSnack => 'bizSecurity_twoFaEnabledSnack'.tr;
  static String get twoFaDisabledSnack => 'bizSecurity_twoFaDisabledSnack'.tr;
  static String get twoFaEnabledBody => 'bizSecurity_twoFaEnabledBody'.tr;
  static String get twoFaDisabledBody => 'bizSecurity_twoFaDisabledBody'.tr;
  static String get sectionActiveSessions =>
      'bizSecurity_sectionActiveSessions'.tr;
  static String get sessionCurrentBadge => 'bizSecurity_sessionCurrentBadge'.tr;
  static String get sessionRevokeButton => 'bizSecurity_sessionRevokeButton'.tr;
  static String get sessionRevokedSnack => 'bizSecurity_sessionRevokedSnack'.tr;
  static String get sessionRevokedBody => 'bizSecurity_sessionRevokedBody'.tr;
  static String get sectionDangerZone => 'bizSecurity_sectionDangerZone'.tr;
  static String get deleteAccountTitle => 'bizSecurity_deleteAccountTitle'.tr;
  static String get deleteAccountSubtitle =>
      'bizSecurity_deleteAccountSubtitle'.tr;
  static String get changePasswordSheetTitle =>
      'bizSecurity_changePasswordSheetTitle'.tr;
  static String get currentPasswordLabel =>
      'bizSecurity_currentPasswordLabel'.tr;
  static String get newPasswordLabel => 'bizSecurity_newPasswordLabel'.tr;
  static String get confirmPasswordLabel =>
      'bizSecurity_confirmPasswordLabel'.tr;
  static String get updatePasswordButton =>
      'bizSecurity_updatePasswordButton'.tr;
  static String get passwordUpdatedSnack =>
      'bizSecurity_passwordUpdatedSnack'.tr;
  static String get passwordUpdatedBody => 'bizSecurity_passwordUpdatedBody'.tr;
  static String get deleteDialogTitle => 'bizSecurity_deleteDialogTitle'.tr;
  static String get deleteDialogBody => 'bizSecurity_deleteDialogBody'.tr;
  static String get deleteDialogCancel => 'bizSecurity_deleteDialogCancel'.tr;
  static String get deleteDialogConfirm => 'bizSecurity_deleteDialogConfirm'.tr;
  static String get closeBusinessTitle => 'bizSecurity_closeBusinessTitle'.tr;
  static String get closeBusinessSubtitle =>
      'bizSecurity_closeBusinessSubtitle'.tr;
  static String get closeDialogTitle => 'bizSecurity_closeDialogTitle'.tr;
  static String get closeDialogBody => 'bizSecurity_closeDialogBody'.tr;
  static String get closeDialogReasonLabel =>
      'bizSecurity_closeDialogReasonLabel'.tr;
  static String get closeDialogReasonHint =>
      'bizSecurity_closeDialogReasonHint'.tr;
  static String get closeDialogReasonRequired =>
      'bizSecurity_closeDialogReasonRequired'.tr;
  static String get closeDialogCancel => 'bizSecurity_closeDialogCancel'.tr;
  static String get closeDialogConfirm => 'bizSecurity_closeDialogConfirm'.tr;
  static String get closeBusinessSuccessSnack =>
      'bizSecurity_closeBusinessSuccessSnack'.tr;
  static String get closeBusinessSuccessBody =>
      'bizSecurity_closeBusinessSuccessBody'.tr;
  static String get closeBusinessErrorSnack =>
      'bizSecurity_closeBusinessErrorSnack'.tr;
}

// ── Operating Hours ───────────────────────────────────────────────────────────
abstract class BusinessHoursStrings {
  static String get appBarTitle => 'bizHours_appBarTitle'.tr;
  static String get infoBanner => 'bizHours_infoBanner'.tr;
  static String get openLabel => 'bizHours_openLabel'.tr;
  static String get closedLabel => 'bizHours_closedLabel'.tr;
  static String get opensChip => 'bizHours_opensChip'.tr;
  static String get closesChip => 'bizHours_closesChip'.tr;
  static String get saveButton => 'bizHours_saveButton'.tr;
  static String get savedSnack => 'bizHours_savedSnack'.tr;
  static String get savedSnackBody => 'bizHours_savedSnackBody'.tr;
  static String get monday => 'bizHours_monday'.tr;
  static String get tuesday => 'bizHours_tuesday'.tr;
  static String get wednesday => 'bizHours_wednesday'.tr;
  static String get thursday => 'bizHours_thursday'.tr;
  static String get friday => 'bizHours_friday'.tr;
  static String get saturday => 'bizHours_saturday'.tr;
  static String get sunday => 'bizHours_sunday'.tr;
}

// ── Push Notifications ────────────────────────────────────────────────────────
abstract class BusinessNotifStrings {
  static String get appBarTitle => 'bizNotif_appBarTitle'.tr;
  static String get saveAction => 'bizNotif_saveAction'.tr;
  static String get savingAction => 'bizNotif_savingAction'.tr;
  static String get savedSnack => 'bizNotif_savedSnack'.tr;
  static String get savedSnackBody => 'bizNotif_savedSnackBody'.tr;
  static String get sectionDevice => 'bizNotif_sectionDevice'.tr;
  static String get pushEnabledTitle => 'bizNotif_pushEnabledTitle'.tr;
  static String get pushEnabledSubtitle => 'bizNotif_pushEnabledSubtitle'.tr;
  static String get sectionOrders => 'bizNotif_sectionOrders'.tr;
  static String get newOrderTitle => 'bizNotif_newOrderTitle'.tr;
  static String get newOrderSubtitle => 'bizNotif_newOrderSubtitle'.tr;
  static String get orderReadyTitle => 'bizNotif_orderReadyTitle'.tr;
  static String get orderReadySubtitle => 'bizNotif_orderReadySubtitle'.tr;
  static String get orderCancelledTitle => 'bizNotif_orderCancelledTitle'.tr;
  static String get orderCancelledSubtitle =>
      'bizNotif_orderCancelledSubtitle'.tr;
  static String get sectionReviews => 'bizNotif_sectionReviews'.tr;
  static String get newReviewTitle => 'bizNotif_newReviewTitle'.tr;
  static String get newReviewSubtitle => 'bizNotif_newReviewSubtitle'.tr;
  static String get reviewReplyTitle => 'bizNotif_reviewReplyTitle'.tr;
  static String get reviewReplySubtitle => 'bizNotif_reviewReplySubtitle'.tr;
  static String get sectionMarketing => 'bizNotif_sectionMarketing'.tr;
  static String get promotionsTitle => 'bizNotif_promotionsTitle'.tr;
  static String get promotionsSubtitle => 'bizNotif_promotionsSubtitle'.tr;
  static String get growthTipsTitle => 'bizNotif_growthTipsTitle'.tr;
  static String get growthTipsSubtitle => 'bizNotif_growthTipsSubtitle'.tr;
  static String get sectionSystem => 'bizNotif_sectionSystem'.tr;
  static String get maintenanceTitle => 'bizNotif_maintenanceTitle'.tr;
  static String get maintenanceSubtitle => 'bizNotif_maintenanceSubtitle'.tr;
  static String get appUpdatesTitle => 'bizNotif_appUpdatesTitle'.tr;
  static String get appUpdatesSubtitle => 'bizNotif_appUpdatesSubtitle'.tr;
  static String get saveBanner => 'bizNotif_saveBanner'.tr;
}

// ── Email Alerts ──────────────────────────────────────────────────────────────
abstract class BusinessEmailStrings {
  static String get appBarTitle => 'bizEmail_appBarTitle'.tr;
  static String get saveAction => 'bizEmail_saveAction'.tr;
  static String get savingAction => 'bizEmail_savingAction'.tr;
  static String get savedSnack => 'bizEmail_savedSnack'.tr;
  static String get savedSnackBody => 'bizEmail_savedSnackBody'.tr;
  static String get sectionReports => 'bizEmail_sectionReports'.tr;
  static String get dailySummaryTitle => 'bizEmail_dailySummaryTitle'.tr;
  static String get dailySummarySubtitle => 'bizEmail_dailySummarySubtitle'.tr;
  static String get weeklyReportTitle => 'bizEmail_weeklyReportTitle'.tr;
  static String get weeklyReportSubtitle => 'bizEmail_weeklyReportSubtitle'.tr;
  static String get monthlyReportTitle => 'bizEmail_monthlyReportTitle'.tr;
  static String get monthlyReportSubtitle =>
      'bizEmail_monthlyReportSubtitle'.tr;
  static String get sectionOrders => 'bizEmail_sectionOrders'.tr;
  static String get orderConfirmTitle => 'bizEmail_orderConfirmTitle'.tr;
  static String get orderConfirmSubtitle => 'bizEmail_orderConfirmSubtitle'.tr;
  static String get refundAlertTitle => 'bizEmail_refundAlertTitle'.tr;
  static String get refundAlertSubtitle => 'bizEmail_refundAlertSubtitle'.tr;
  static String get sectionReviews => 'bizEmail_sectionReviews'.tr;
  static String get newReviewTitle => 'bizEmail_newReviewTitle'.tr;
  static String get newReviewSubtitle => 'bizEmail_newReviewSubtitle'.tr;
  static String get lowRatingTitle => 'bizEmail_lowRatingTitle'.tr;
  static String get lowRatingSubtitle => 'bizEmail_lowRatingSubtitle'.tr;
  static String get saveBanner => 'bizEmail_saveBanner'.tr;
}

// ── Photos & Branding ─────────────────────────────────────────────────────────
abstract class BusinessPhotosStrings {
  static String get appBarTitle => 'bizPhotos_appBarTitle'.tr;
  static String get logoTitle => 'bizPhotos_logoTitle'.tr;
  static String get logoSubtitle => 'bizPhotos_logoSubtitle'.tr;
  static String get tapToChangeLogo => 'bizPhotos_tapToChangeLogo'.tr;
  static String get coverTitle => 'bizPhotos_coverTitle'.tr;
  static String get coverSubtitle => 'bizPhotos_coverSubtitle'.tr;
  static String get uploadCoverButton => 'bizPhotos_uploadCoverButton'.tr;
  static String get coverRecommendedSize => 'bizPhotos_coverRecommendedSize'.tr;
  static String get galleryTitle => 'bizPhotos_galleryTitle'.tr;
  static String get gallerySubtitle => 'bizPhotos_gallerySubtitle'.tr;
  static String get tipText => 'bizPhotos_tipText'.tr;
  static String get comingSoonSnack => 'bizPhotos_comingSoonSnack'.tr;
  static String get comingSoonBody => 'bizPhotos_comingSoonBody'.tr;
  static String photoSlot(int n) => 'bizPhotos_photoSlot'.trParams({
    'n': CurrencyFormatter.localizeDigits('$n'),
  });
}

// ── Team Members ──────────────────────────────────────────────────────────────
abstract class BusinessTeamStrings {
  static String get appBarTitle => 'bizTeam_appBarTitle'.tr;
  static String get inviteButton => 'bizTeam_inviteButton'.tr;
  static String get retryButton => 'bizTeam_retryButton'.tr;
  static String get descriptionText => 'bizTeam_descriptionText'.tr;
  static String get emptyTitle => 'bizTeam_emptyTitle'.tr;
  static String get emptySubtitle => 'bizTeam_emptySubtitle'.tr;
  static String get inviteFirstButton => 'bizTeam_inviteFirstButton'.tr;
  static String get editPermissionsTooltip =>
      'bizTeam_editPermissionsTooltip'.tr;
  static String get removeMemberTooltip => 'bizTeam_removeMemberTooltip'.tr;
  static String get noPermissions => 'bizTeam_noPermissions'.tr;
  static String get removeDialogTitle => 'bizTeam_removeDialogTitle'.tr;
  static String get removeDialogCancel => 'bizTeam_removeDialogCancel'.tr;
  static String get removeDialogConfirm => 'bizTeam_removeDialogConfirm'.tr;
  static String get removedSnackBody => 'bizTeam_removedSnackBody'.tr;
  static String get removeFailedSnack => 'bizTeam_removeFailedSnack'.tr;
  static String get permissionsUpdatedSnack =>
      'bizTeam_permissionsUpdatedSnack'.tr;
  static String get dashboardAccessLabel => 'bizTeam_dashboardAccessLabel'.tr;
  static String get saveChangesButton => 'bizTeam_saveChangesButton'.tr;
  static String get inviteSheetTitle => 'bizTeam_inviteSheetTitle'.tr;
  static String get emailFieldLabel => 'bizTeam_emailFieldLabel'.tr;
  static String get roleFieldLabel => 'bizTeam_roleFieldLabel'.tr;
  static String get roleFieldHint => 'bizTeam_roleFieldHint'.tr;
  static String get roleFieldOptional => 'bizTeam_roleFieldOptional'.tr;
  static String get permissionsFieldLabel => 'bizTeam_permissionsFieldLabel'.tr;
  static String get permissionsFieldHint => 'bizTeam_permissionsFieldHint'.tr;
  static String get selectPermissionHint => 'bizTeam_selectPermissionHint'.tr;
  static String get sendInviteButton => 'bizTeam_sendInviteButton'.tr;
  static String get sendingButton => 'bizTeam_sendingButton'.tr;
  static String get emailRequired => 'bizTeam_emailRequired'.tr;
  static String get emailInvalid => 'bizTeam_emailInvalid'.tr;
  static String get inviteFailedSnack => 'bizTeam_inviteFailedSnack'.tr;

  static String removeDialogBody(String name) =>
      'bizTeam_removeDialogBody'.trParams({'name': name});
  static String inviteSentSnack(String email) =>
      'bizTeam_inviteSentSnack'.trParams({'email': email});
  static String removedSnack(String name) =>
      'bizTeam_removedSnack'.trParams({'name': name});
}

// ── Help & Support ────────────────────────────────────────────────────────────
abstract class BusinessHelpStrings {
  static String get appBarTitle => 'bizHelp_appBarTitle'.tr;
  static String get getInTouch => 'bizHelp_getInTouch'.tr;
  static String get liveChat => 'bizHelp_liveChat'.tr;
  static String get liveChatSub => 'bizHelp_liveChatSub'.tr;
  static String get email => 'bizHelp_email'.tr;
  static String get emailSub => 'bizHelp_emailSub'.tr;
  static String get call => 'bizHelp_call'.tr;
  static String get callSub => 'bizHelp_callSub'.tr;
  static String get snackChat => 'bizHelp_snackChat'.tr;
  static String get snackEmail => 'bizHelp_snackEmail'.tr;
  static String get snackCall => 'bizHelp_snackCall'.tr;
  static String get snackCentre => 'bizHelp_snackCentre'.tr;
  static String get faqTitle => 'bizHelp_faqTitle'.tr;
  static String get visitCentre => 'bizHelp_visitCentre'.tr;
  static String get centreSub => 'bizHelp_centreSub'.tr;

  static List<({String q, String a})> get faqs => [
    (q: 'bizHelp_faq0Q'.tr, a: 'bizHelp_faq0A'.tr),
    (q: 'bizHelp_faq1Q'.tr, a: 'bizHelp_faq1A'.tr),
    (q: 'bizHelp_faq2Q'.tr, a: 'bizHelp_faq2A'.tr),
    (q: 'bizHelp_faq3Q'.tr, a: 'bizHelp_faq3A'.tr),
    (q: 'bizHelp_faq4Q'.tr, a: 'bizHelp_faq4A'.tr),
    (q: 'bizHelp_faq5Q'.tr, a: 'bizHelp_faq5A'.tr),
  ];
}

// ── About ─────────────────────────────────────────────────────────────────────
abstract class BusinessAboutStrings {
  static String get appBarTitle => 'bizAbout_appBarTitle'.tr;
  static String get sectionLegal => 'bizAbout_sectionLegal'.tr;
  static String get termsOfService => 'bizAbout_termsOfService'.tr;
  static String get privacyPolicy => 'bizAbout_privacyPolicy'.tr;
  static String get cookiePolicy => 'bizAbout_cookiePolicy'.tr;
  static String get sectionFollowUs => 'bizAbout_sectionFollowUs'.tr;
  static String get businessPartnerApp => 'bizAbout_businessPartnerApp'.tr;
  static String get versionPrefix => 'bizAbout_versionPrefix'.tr;
  static String get rateUsTitle => 'bizAbout_rateUsTitle'.tr;
  static String get rateUsSub => 'bizAbout_rateUsSub'.tr;
  static String get rateUsSnackTitle => 'bizAbout_rateUsSnackTitle'.tr;
  static String get rateUsSnackBody => 'bizAbout_rateUsSnackBody'.tr;
  static String get termsSnackTitle => 'bizAbout_termsSnackTitle'.tr;
  static String get termsSnackBody => 'bizAbout_termsSnackBody'.tr;
  static String get privacySnackTitle => 'bizAbout_privacySnackTitle'.tr;
  static String get privacySnackBody => 'bizAbout_privacySnackBody'.tr;
  static String get cookiesSnackTitle => 'bizAbout_cookiesSnackTitle'.tr;
  static String get cookiesSnackBody => 'bizAbout_cookiesSnackBody'.tr;
  static String get openingInstagram => 'bizAbout_openingInstagram'.tr;
  static String get openingTwitter => 'bizAbout_openingTwitter'.tr;
  static String get copyright => 'bizAbout_copyright'.tr;
}

// ── Cache service ─────────────────────────────────────────────────────────────
// CacheStrings moved to package:i18n (shared with CacheService).

// ── Settings page sections ────────────────────────────────────────────────────
abstract class SettingsPageStrings {
  static String get sectionPreferences => 'settings_sectionPreferences'.tr;
  static String get sectionAccountSecurity =>
      'settings_sectionAccountSecurity'.tr;
  static String get sectionSupport => 'settings_sectionSupport'.tr;
  static String get pushNotifications => 'settings_pushNotifications'.tr;
  static String get emailAlerts => 'settings_emailAlerts'.tr;
  static String get security => 'settings_security'.tr;
  static String get helpSupport => 'settings_helpSupport'.tr;
  static String get about => 'settings_about_item'.tr;
}

// ── Business Locations (Addresses) ────────────────────────────────────────────
abstract class BusinessAddressStrings {
  static String get appBarTitle => 'bizAddr_appBarTitle'.tr;
  static String get noLocations => 'bizAddr_noLocations'.tr;
  static String get noLocationsBody => 'bizAddr_noLocationsBody'.tr;
  static String get addNewLocation => 'bizAddr_addNewLocation'.tr;
  static String get editLocation => 'bizAddr_editLocation'.tr;
  static String get primaryBadge => 'bizAddr_primaryBadge'.tr;
  static String get labelMain => 'bizAddr_labelMain'.tr;
  static String get labelBranch => 'bizAddr_labelBranch'.tr;
  static String get labelWarehouse => 'bizAddr_labelWarehouse'.tr;
  static String get labelOther => 'bizAddr_labelOther'.tr;
  static String get streetLabel => 'bizAddr_streetLabel'.tr;
  static String get street2Label => 'bizAddr_street2Label'.tr;
  static String get cityLabel => 'bizAddr_cityLabel'.tr;
  static String get postalLabel => 'bizAddr_postalLabel'.tr;
  static String get countryLabel => 'bizAddr_countryLabel'.tr;
  static String get countryCodeLabel => 'bizAddr_countryCodeLabel'.tr;
  static String get stateLabel => 'bizAddr_stateLabel'.tr;
  static String get latLabel => 'bizAddr_latLabel'.tr;
  static String get lngLabel => 'bizAddr_lngLabel'.tr;
  static String get saveButton => 'bizAddr_saveButton'.tr;
  static String get locationSaved => 'bizAddr_locationSaved'.tr;
  static String get locationUpdated => 'bizAddr_locationUpdated'.tr;
  static String get locationDeleted => 'bizAddr_locationDeleted'.tr;
  static String get deleteTitle => 'bizAddr_deleteTitle'.tr;
  static String get deleteBody => 'bizAddr_deleteBody'.tr;
  static String get deleteLastWarning => 'bizAddr_deleteLastWarning'.tr;
  static String get deleteConfirm => 'bizAddr_deleteConfirm'.tr;
  static String get deleteCancel => 'bizAddr_deleteCancel'.tr;
  static String get setPrimary => 'bizAddr_setPrimary'.tr;
  static String get setPrimarySuccess => 'bizAddr_setPrimarySuccess'.tr;
}

// ── Business Settings Page ────────────────────────────────────────────────────
abstract class BusinessSettingsPageStrings {
  static String get sectionBusiness => 'bizSettingsPage_sectionBusiness'.tr;
  static String get businessProfile => 'bizSettingsPage_businessProfile'.tr;
  static String get businessProfileSub =>
      'bizSettingsPage_businessProfileSub'.tr;
  static String get operatingHours => 'bizSettingsPage_operatingHours'.tr;
  static String get operatingHoursSub => 'bizSettingsPage_operatingHoursSub'.tr;
  static String get photosBranding => 'bizSettingsPage_photosBranding'.tr;
  static String get photosBrandingSub => 'bizSettingsPage_photosBrandingSub'.tr;
  static String get locations => 'bizSettingsPage_locations'.tr;
  static String get locationsSub => 'bizSettingsPage_locationsSub'.tr;
  static String get sectionTeam => 'bizSettingsPage_sectionTeam'.tr;
  static String get teamMembers => 'bizSettingsPage_teamMembers'.tr;
  static String get teamMembersSub => 'bizSettingsPage_teamMembersSub'.tr;
  static String get sectionNotifications =>
      'bizSettingsPage_sectionNotifications'.tr;
  static String get pushNotifications => 'bizSettingsPage_pushNotifications'.tr;
  static String get pushNotificationsSub =>
      'bizSettingsPage_pushNotificationsSub'.tr;
  static String get emailAlerts => 'bizSettingsPage_emailAlerts'.tr;
  static String get emailAlertsSub => 'bizSettingsPage_emailAlertsSub'.tr;
  static String get sectionAccount => 'bizSettingsPage_sectionAccount'.tr;
  static String get security => 'bizSettingsPage_security'.tr;
  static String get securitySub => 'bizSettingsPage_securitySub'.tr;
  static String get helpSupport => 'bizSettingsPage_helpSupport'.tr;
  static String get about => 'bizSettingsPage_about'.tr;
  static String get clearCache => 'bizSettingsPage_clearCache'.tr;
  static String get clearCacheSub => 'bizSettingsPage_clearCacheSub'.tr;
}

// ── Email Alerts Banner ───────────────────────────────────────────────────────
abstract class BusinessEmailBannerStrings {
  static String get bannerLabel => 'bizEmail_bannerLabel'.tr;
  static String get bannerAddress => 'bizEmail_bannerAddress'.tr;
}

// ── Business Profile Screen ───────────────────────────────────────────────────
abstract class BusinessProfileStrings {
  static String get appBarTitle => 'bizProfile_appBarTitle'.tr;
  static String get couldNotLoad => 'bizProfile_couldNotLoad'.tr;
  static String get retry => 'bizProfile_retry'.tr;
  static String get sectionBusinessDetails =>
      'bizProfile_sectionBusinessDetails'.tr;
  static String get labelBusinessName => 'bizProfile_labelBusinessName'.tr;
  static String get labelOwner => 'bizProfile_labelOwner'.tr;
  static String get labelRegistrationNumber =>
      'bizProfile_labelRegistrationNumber'.tr;
  static String get labelKycStatus => 'bizProfile_labelKycStatus'.tr;
  static String get sectionTaxInfo => 'bizProfile_sectionTaxInfo'.tr;
  static String get labelTaxNumber => 'bizProfile_labelTaxNumber'.tr;
  static String get statRating => 'bizProfile_statRating'.tr;
  static String get statDelivery => 'bizProfile_statDelivery'.tr;
  static String get statStatus => 'bizProfile_statStatus'.tr;
  static String get statCash => 'bizProfile_statCash'.tr;
  static String get statusOpen => 'bizProfile_statusOpen'.tr;
  static String get statusClosed => 'bizProfile_statusClosed'.tr;
  static String get cashYes => 'bizProfile_cashYes'.tr;
  static String get cashNo => 'bizProfile_cashNo'.tr;
  static String get sectionLocations => 'bizProfile_sectionLocations'.tr;
  static String get primaryBadge => 'bizProfile_primaryBadge'.tr;
  static String get sectionPayment => 'bizProfile_sectionPayment'.tr;
  static String get cashToggleTitle => 'bizProfile_cashToggleTitle'.tr;
  static String get cashToggleOnSub => 'bizProfile_cashToggleOnSub'.tr;
  static String get cashToggleOffSub => 'bizProfile_cashToggleOffSub'.tr;
  static String get cashHint => 'bizProfile_cashHint'.tr;
  static String get deliveryFeeTitle => 'bizProfile_deliveryFeeTitle'.tr;
  static String get deliveryFeeSub => 'bizProfile_deliveryFeeSub'.tr;
  static String get deliveryFeeHint => 'bizProfile_deliveryFeeHint'.tr;
  static String get deliveryFeeSaveButton =>
      'bizProfile_deliveryFeeSaveButton'.tr;
  static String get deliveryFeeSavedSnack =>
      'bizProfile_deliveryFeeSavedSnack'.tr;
  static String get deliveryFeeInvalid => 'bizProfile_deliveryFeeInvalid'.tr;
}
