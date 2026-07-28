import 'package:flutter/material.dart';

abstract class AppColors {
  // =========================
  // Brand (Adopted Too Good To Go Teal / Emerald Theme)
  // =========================

  static const primary = Color(
    0xFF026863,
  ); // Deep Forest Teal (Selected Filter / Primary Accent)
  static const primaryDark = Color(0xFF005C53); // Darker Teal Variant
  static const primaryDark1 = Color(0xFF01524E); // 1 level darker
  static const primaryDark2 = Color(
    0xFF013C39,
  ); // 2 levels darker APP-Bar nad Navbar
  static const primaryLight = Color(0xFFE8F4F3); // Soft Mint/Teal Tint
  static const primaryLight1 = Color(0xFFE0ECEB); // 1 level lighter/softer
  static const primaryLight2 = Color(0xFFF0F6F5); // 2 levels lighter/softer

  static const accent = Color(0xFFEF9F27);
  static const accentDark = Color(0xFFD68610);
  static const accentLight = Color(0xFFFFF4E3);

  static const Color ink = Color(0xFF1C2526); // Dark charcoal text
  static const Color textMuted = Color(0xFF5F6B6A); // Secondary muted text
  static const Color hint = Color(0xFF9CA3AF);

  // =========================
  // Unselected Chip / Filter Badges (Soft Cream Theme)
  // =========================

  static const Color unselectedFilterBg = Color(
    0xFFF5EFEE,
  ); // Warm Cream/Beige for unselected chips
  static const Color unselectedFilterText = Color(
    0xFF026863,
  ); // Dark Teal text on unselected chips

  // =========================
  // Neutral / Backgrounds
  // =========================

  static const background = Color(0xFFFAFAFA); // Warm Off-White Page Background
  static const surface = Color(0xFFFFFFFF); // Pure White
  static const card = Color(0xFFFFFFFF); // Pure White Card Containers

  static const border = Color(0xFFE5E5E2);
  static const divider = Color(0xFFF0F0EE);
  static const Color field = Color(0xFFF5EFEE); // Soft input background

  // =========================
  // Gray Scale
  // =========================

  static const gray50 = Color(0xFFFAFAFA);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF5F6B6A);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF1C2526);

  // =========================
  // Text
  // =========================

  static const textPrimary = gray900; // Primary Charcoal Title Text
  static const textSecondary = gray600; // Subtitles / Distances / Pickup Times
  static const textTertiary = gray500;
  static const textHint = gray400;

  static const textWhite = Colors.white;
  static const textBlack87 = Color(0xDD000000);

  // =========================
  // Status
  // =========================

  // Success
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const successDark = Color(0xFF15803D);

  // Error
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const errorDark = Color(0xFFB91C1C);

  // Warning
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const warningDark = Color(0xFFD97706);

  // Info
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);
  static const infoDark = Color(0xFF1D4ED8);

  // =========================
  // Extra Colors
  // =========================

  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFEDE9FE);

  static const pink = Color(0xFFEC4899);
  static const pinkLight = Color(0xFFFCE7F3);

  static const cyan = Color(0xFF06B6D4);
  static const cyanLight = Color(0xFFCFFAFE);

  // =========================
  // Utility
  // =========================

  static const transparent = Colors.transparent;
  static const white = Colors.white;
  static const black = Colors.black;
  static const black54 = Color(0x8A000000); // semi-transparent black overlay
  static const black12 = Color(0x1F000000); // very light overlay / ripple

  static const disabled = gray300;
  static const shadow = Color(0x1A000000);

  // =========================
  // Brand / Splash
  // =========================

  static const splashGradientStart = Color(0xFFFF7E5F);
  static const splashGradientEnd = Color(0xFFFF3D68);

  // Page header gradient matching new primary theme
  static const headerGradientStart = Color(0xFF028A83);
  static const headerGradientEnd = Color(0xFF026863); // = primary

  // =========================
  // Extra Colors (additional)
  // =========================

  static const navy = Color(0xFF1A2B4A);
  static const warningDeep = Color(0xFFEF6C00);

  // =========================
  // Perka Locked Shell (AppBar + BottomNav)
  // =========================
  // static const Color shellBackground = Color(0xFF1A237E); // Deep Royal Indigo
  // static const Color shellForeground = Colors.white;
  // static const Color shellForegroundMuted = Color(0xFFC5CAE9);
  // static const Color activeTabGold = Color(
  //   0xFFFFC107,

  // ); // active bottom-tab highlight
  static const Color shellBackground = Color(0xFF013C39); // Deep Royal Indigo
  static const Color shellForeground = Color(0xFFC5CAE9);
  static const Color shellForegroundMuted = Color(0xFFC5CAE9);
  static const Color activeTabGold = Color(
    0xFFE8F4F3,
  ); // active bottom-tab highlight

  // =========================
  // Perka Market Accents
  // =========================
  static const Color foodAccent = Color(0xFFE65100); // Warm Red-Orange
  static const Color cosmeticAccent = Color(0xFF6A1B9A); // Vivid Royal Violet
  static const Color clothesAccent = Color(0xFF263238); // Sleek Charcoal
}
