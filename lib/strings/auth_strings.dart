import 'package:get/get.dart';

abstract class AuthStrings {
  static String get login => 'auth_login'.tr;
  static String get register => 'auth_register'.tr;
  static String get email => 'auth_email'.tr;
  static String get password => 'auth_password'.tr;
  static String get welcomeBack => 'auth_welcomeBack'.tr;
  static String get welcomeBackSubtitle => 'auth_welcomeBackSubtitle'.tr;
  static String get emailOrUsername => 'auth_emailOrUsername'.tr;
  static String get emailHint => 'auth_emailHint'.tr;
  static String get emailRequired => 'auth_emailRequired'.tr;
  static String get passwordMin => 'auth_passwordMin'.tr;
  static String get forgotPassword => 'auth_forgotPassword'.tr;
  static String get signIn => 'auth_signIn'.tr;
  static String get noAccount => 'auth_noAccount'.tr;
  static String get signUp => 'auth_signUp'.tr;
  static String get appBrandName => 'auth_appBrandName'.tr;
}

abstract class RegisterStrings {
  static String get title => 'register_title'.tr;
  static String get subtitle => 'register_subtitle'.tr;
  static String get iWantTo => 'register_iWantTo'.tr;
  static String get orderFood => 'register_orderFood'.tr;
  static String get orderFoodSubtitle => 'register_orderFoodSubtitle'.tr;
  static String get sellFood => 'register_sellFood'.tr;
  static String get sellFoodSubtitle => 'register_sellFoodSubtitle'.tr;
  static String get businessName => 'register_businessName'.tr;
  static String get businessNameHint => 'register_businessNameHint'.tr;
  static String get fullName => 'register_fullName'.tr;
  static String get fullNameHint => 'register_fullNameHint'.tr;
  static String get phone => 'register_phone'.tr;
  static String get phoneHint => 'register_phoneHint'.tr;
  static String get deliveryAddress => 'register_deliveryAddress'.tr;
  static String get businessAddress => 'register_businessAddress'.tr;
  static String get deliveryAddressSubtitle =>
      'register_deliveryAddressSubtitle'.tr;
  static String get businessAddressSubtitle =>
      'register_businessAddressSubtitle'.tr;
  static String get addrHome => 'register_addrHome'.tr;
  static String get addrWork => 'register_addrWork'.tr;
  static String get addrOther => 'register_addrOther'.tr;
  static String get addrOffice => 'register_addrOffice'.tr;
  static String get addrBranch => 'register_addrBranch'.tr;
  static String get street => 'register_street'.tr;
  static String get street2 => 'register_street2'.tr;
  static String get city => 'register_city'.tr;
  static String get postcode => 'register_postcode'.tr;
  static String get country => 'register_country'.tr;
  static String get countryCode => 'register_countryCode'.tr;
  static String get passwordRules => 'register_passwordRules'.tr;
  static String get submitUser => 'register_submitUser'.tr;
  static String get submitBusiness => 'register_submitBusiness'.tr;
  static String get termsPrefix => 'register_termsPrefix'.tr;
  static String get terms => 'register_terms'.tr;
  static String get privacyPolicy => 'register_privacyPolicy'.tr;
  static String get haveAccount => 'register_haveAccount'.tr;
  static String get errNameRequired => 'register_errNameRequired'.tr;
  static String get errEmailRequired => 'register_errEmailRequired'.tr;
  static String get errEmailInvalid => 'register_errEmailInvalid'.tr;
  static String get errPasswordRequired => 'register_errPasswordRequired'.tr;
  static String get errPasswordLength => 'register_errPasswordLength'.tr;
  static String get errPasswordUpper => 'register_errPasswordUpper'.tr;
  static String get errPasswordLower => 'register_errPasswordLower'.tr;
  static String get errPasswordNumber => 'register_errPasswordNumber'.tr;
  static String get errBusinessNameRequired =>
      'register_errBusinessNameRequired'.tr;
  static String get failed => 'register_failed'.tr;
}

abstract class ForgotPasswordStrings {
  static String get title => 'forgotPwd_title'.tr;
  static String get subtitle => 'forgotPwd_subtitle'.tr;
  static String get emailField => 'forgotPwd_emailField'.tr;
  static String get emailInvalid => 'forgotPwd_emailInvalid'.tr;
  static String get button => 'forgotPwd_button'.tr;
  static String get successTitle => 'forgotPwd_successTitle'.tr;
  static String get successBody => 'forgotPwd_successBody'.tr;
  static String get backToLogin => 'forgotPwd_backToLogin'.tr;
  static String get errorTitle => 'forgotPwd_errorTitle'.tr;
}

abstract class EmailVerifNoticeStrings {
  static String get waitingTitle => 'emailVerifNotice_waitingTitle'.tr;
  static String get verifiedTitle => 'emailVerifNotice_verifiedTitle'.tr;
  static String get verifiedSnackbar => 'emailVerifNotice_verifiedSnackbar'.tr;
  static String get sentTo => 'emailVerifNotice_sentTo'.tr;
  static String get readySigningIn => 'emailVerifNotice_readySigningIn'.tr;
  static String get hint => 'emailVerifNotice_hint'.tr;
  static String get waiting => 'emailVerifNotice_waiting'.tr;
  static String get resend => 'emailVerifNotice_resend'.tr;
  static String get signInVerified => 'emailVerifNotice_signInVerified'.tr;
  static String get signInManual => 'emailVerifNotice_signInManual'.tr;
}
