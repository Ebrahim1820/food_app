import 'package:get/get.dart';

/// Strings for the Impact Tracker feature (customer + business).
abstract class ImpactStrings {
  // ── Hero card (embedded on Profile / Overview) ────────────────────────────
  static String get heroTitle => 'impact_heroTitle'.tr;
  static String get heroSubtitleCustomer => 'impact_heroSubtitleCustomer'.tr;
  static String get heroSubtitleBusiness => 'impact_heroSubtitleBusiness'.tr;
  static String get heroCta => 'impact_heroCta'.tr;

  // ── Full screen ────────────────────────────────────────────────────────────
  static String get screenTitleCustomer => 'impact_screenTitleCustomer'.tr;
  static String get screenTitleBusiness => 'impact_screenTitleBusiness'.tr;
  static String get heroBannerSubtitleCustomer =>
      'impact_heroBannerSubtitleCustomer'.tr;
  static String get heroBannerSubtitleBusiness =>
      'impact_heroBannerSubtitleBusiness'.tr;

  // ── Stat labels ────────────────────────────────────────────────────────────
  static String get statMeals => 'impact_statMeals'.tr;
  static String get statCo2 => 'impact_statCo2'.tr;
  static String get statWater => 'impact_statWater'.tr;
  static String get statLand => 'impact_statLand'.tr;
  static String get statOrders => 'impact_statOrders'.tr;

  // ── Equivalences ───────────────────────────────────────────────────────────
  static String get equivalencesTitle => 'impact_equivalencesTitle'.tr;
  static String eqTrees(String n) =>
      'impact_eqTrees'.trParams({'n': n});
  static String eqShowers(String n) =>
      'impact_eqShowers'.trParams({'n': n});
  static String eqCarKm(String n) =>
      'impact_eqCarKm'.trParams({'n': n});

  // ── Empty state ────────────────────────────────────────────────────────────
  static String get emptyTitle => 'impact_emptyTitle'.tr;
  static String get emptySubtitleCustomer =>
      'impact_emptySubtitleCustomer'.tr;
  static String get emptySubtitleBusiness =>
      'impact_emptySubtitleBusiness'.tr;

  // ── Footer ─────────────────────────────────────────────────────────────────
  static String get footerNote => 'impact_footerNote'.tr;
}
