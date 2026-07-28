import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData forLocale(Locale locale) =>
      locale.languageCode == 'fa' ? persian : light;

  static ThemeData get persian {
    final base = light;
    return base.copyWith(
      textTheme: GoogleFonts.vazirmatnTextTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: GoogleFonts.vazirmatn().fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          textStyle: WidgetStateProperty.all(
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.vazirmatn().fontFamily,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          textStyle: WidgetStateProperty.all(
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.vazirmatn().fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Nunito', // add to pubspec.yaml fonts section
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontFamily: 'Nunito',
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),

    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Nunito',
        ),
        elevation: 0,
      ),
    ),

    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Nunito',
        ),
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),

    // Text
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
  );
}
