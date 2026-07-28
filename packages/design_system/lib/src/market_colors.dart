import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'app_colors.dart';

/// Single source of truth mapping a backend market key
/// (`DashboardMarket.key` / `businessCapabilities` key) to its brand accent
/// colour — the Perka design system's per-section CTA/chip/badge colour.
/// NOT the shell colour: the AppBar/BottomNav shell is deliberately locked
/// to `AppColors.shellBackground` on every screen regardless of market (see
/// `DashboardShell`) — this map only drives dynamic, in-page accents like
/// "Add to Cart" buttons and active filter chips.
Map<String, Color> marketColorMap = {
  Market.food.value: AppColors.foodAccent, // appetite & fast decisions
  Market.cosmetic.value: AppColors.cosmeticAccent, // luxury & self-care
  'clothes': AppColors.clothesAccent, // minimal, lets photography stand out
};

/// Accent colour for [key], falling back to the neutral Dashboard/hub accent
/// (Perka's "Master Indigo") for any market key the app doesn't recognise
/// yet (electronics, home_appliances, auto_equipment, or an unbuilt future
/// market).
Color marketAccent(String? key) =>
    marketColorMap[key] ?? AppColors.shellBackground;
