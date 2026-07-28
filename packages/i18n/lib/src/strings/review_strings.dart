import 'package:get/get.dart';

abstract class ReviewStrings {
  // ── Rate-order CTA (order detail screen) ──────────────────────────────────
  static String get rateOrderButton => 'review_rateOrderButton'.tr;
  static String get alreadyRatedLabel => 'review_alreadyRatedLabel'.tr;

  // ── Submit-review sheet ────────────────────────────────────────────────────
  static String get sheetTitle => 'review_sheetTitle'.tr;
  static String sheetSubtitle(String businessName) =>
      'review_sheetSubtitle'.trParams({'name': businessName});
  static String get commentHint => 'review_commentHint'.tr;
  static String get submitButton => 'review_submitButton'.tr;
  static String get cancelButton => 'review_cancelButton'.tr;
  static String get starsRequiredError => 'review_starsRequiredError'.tr;

  static String get submitSuccessTitle => 'review_submitSuccessTitle'.tr;
  static String get submitSuccessBody => 'review_submitSuccessBody'.tr;
  static String get submitErrorBody => 'review_submitErrorBody'.tr;
  static String get alreadyReviewedTitle => 'review_alreadyReviewedTitle'.tr;
  static String get alreadyReviewedBody => 'review_alreadyReviewedBody'.tr;

  // ── Reviews list (customer-facing "Ratings & Reviews" + business tab) ──────
  static String get screenTitle => 'review_screenTitle'.tr;
  static String get outOfFive => 'review_outOfFive'.tr;
  static String get seeAllReviews => 'review_seeAllReviews'.tr;
  static String get anonymousReviewer => 'review_anonymousReviewer'.tr;
  static String get emptyTitle => 'review_emptyTitle'.tr;
  static String get emptySubtitle => 'review_emptySubtitle'.tr;
  static String get bizEmptySubtitle => 'review_bizEmptySubtitle'.tr;

  static String reviewCount(int n) =>
      (n == 1 ? 'review_countOne' : 'review_countOther').trParams({'n': '$n'});
}
