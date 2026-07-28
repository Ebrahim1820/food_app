import 'package:get/get.dart';

abstract class BusinessBankAccountScreenStrings {
  // ── App bar & section headers ─────────────────────────────────────────────
  static String get appBarTitle => 'bizBank_appBarTitle'.tr;
  static String get sectionBankAccounts => 'bizBank_sectionBankAccounts'.tr;
  static String get sectionPaymentSettings =>
      'bizBank_sectionPaymentSettings'.tr;

  // ── Add button (section header) ───────────────────────────────────────────
  static String get addAccountButton => 'bizBank_addAccountButton'.tr;

  // ── Empty state ───────────────────────────────────────────────────────────
  static String get emptyTitle => 'bizBank_emptyTitle'.tr;
  static String get emptySubtitle => 'bizBank_emptySubtitle'.tr;
  static String get emptyAddButton => 'bizBank_emptyAddButton'.tr;

  // ── Account card ──────────────────────────────────────────────────────────
  static String get cardFallbackName => 'bizBank_cardFallbackName'.tr;
  static String get cardCopyIban => 'bizBank_cardCopyIban'.tr;
  static String get cardIbanCopied => 'bizBank_cardIbanCopied'.tr;

  // ── Delete dialog ─────────────────────────────────────────────────────────
  static String get deleteDialogTitle => 'bizBank_deleteDialogTitle'.tr;
  static String get deleteDialogConfirm => 'bizBank_deleteDialogConfirm'.tr;
  static String get deleteDialogCancel => 'bizBank_deleteDialogCancel'.tr;

  static String deleteDialogBody(String name) =>
      'bizBank_deleteDialogBody'.trParams({'name': name});

  // ── Bottom sheet titles ───────────────────────────────────────────────────
  static String get sheetTitleAdd => 'bizBank_sheetTitleAdd'.tr;
  static String get sheetTitleEdit => 'bizBank_sheetTitleEdit'.tr;

  // ── Form field labels & hints ─────────────────────────────────────────────
  static String get fieldBankName => 'bizBank_fieldBankName'.tr;
  static String get fieldBankNameHint => 'bizBank_fieldBankNameHint'.tr;
  static String get fieldHolderName => 'bizBank_fieldHolderName'.tr;
  static String get fieldHolderNameHint => 'bizBank_fieldHolderNameHint'.tr;
  static String get fieldIban => 'bizBank_fieldIban'.tr;
  static String get fieldIbanHint => 'bizBank_fieldIbanHint'.tr;
  static String get fieldSwift => 'bizBank_fieldSwift'.tr;
  static String get fieldSwiftHint => 'bizBank_fieldSwiftHint'.tr;
  static String get fieldAccountNumber => 'bizBank_fieldAccountNumber'.tr;
  static String get fieldAccountNumberHint =>
      'bizBank_fieldAccountNumberHint'.tr;
  static String get fieldRequired => 'bizBank_fieldRequired'.tr;

  // ── Default toggle ────────────────────────────────────────────────────────
  static String get defaultToggleLabel => 'bizBank_defaultToggleLabel'.tr;
  static String get defaultToggleSubtitle => 'bizBank_defaultToggleSubtitle'.tr;

  // ── Save button ───────────────────────────────────────────────────────────
  static String get saveButton => 'bizBank_saveButton'.tr;
  static String get addButton => 'bizBank_addButton'.tr;

  // ── Cash toggle ───────────────────────────────────────────────────────────
  static String get cashToggleLabel => 'bizBank_cashToggleLabel'.tr;
  static String get cashToggleOnSubtitle => 'bizBank_cashToggleOnSubtitle'.tr;
  static String get cashToggleOffSubtitle => 'bizBank_cashToggleOffSubtitle'.tr;

  // ── Hint banner ───────────────────────────────────────────────────────────
  static String get cashHintBanner => 'bizBank_cashHintBanner'.tr;

  // ── Retry ─────────────────────────────────────────────────────────────────
  static String get retryButton => 'bizBank_retryButton'.tr;
  static String get errorCouldNotLoad => 'bizBank_errorCouldNotLoad'.tr;

  // ── Snackbars (from BankAccountController) ────────────────────────────────
  static String get snackAdded => 'bizBank_snackAdded'.tr;
  static String get snackUpdated => 'bizBank_snackUpdated'.tr;
  static String get snackDeleted => 'bizBank_snackDeleted'.tr;
  static String get snackCouldNotSave => 'bizBank_snackCouldNotSave'.tr;
  static String get snackCouldNotUpdate => 'bizBank_snackCouldNotUpdate'.tr;
  static String get snackCouldNotDelete => 'bizBank_snackCouldNotDelete'.tr;
}

// ── Payment method badge labels (BusinessOrderCard) ──────────────────────────

abstract class PaymentMethodStrings {
  static String get cash => 'payment_methodCash'.tr;
  static String get card => 'payment_methodCard'.tr;
}
