// lib/features/dashboard/dashboard_home_tiles.dart
//
// The market-tile grid — extracted from the old standalone DashboardScreen
// so it can plug in as AppShellScreen's Home-tab body when no market is
// selected yet (NavigationController.activeMarket == null). Chrome
// (AppBar/Drawer/BottomNav) now lives once in AppShellScreen, not here.

import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/controllers/dashboard_controller.dart';
import 'package:food_app/widgets/dashboard_icons.dart';
import 'package:food_app/widgets/dashboard/widgets/dashboard_skeleton.dart';
import 'package:food_app/widgets/dashboard/widgets/hero_market_tile.dart';
import 'package:food_app/widgets/dashboard/widgets/market_tile.dart';
import 'package:food_app/widgets/dashboard/widgets/secondary_market_tile.dart';
import 'package:food_app/models/dashboard_model.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/stale_banner.dart';
import 'package:get/get.dart';

class DashboardHomeTiles extends StatelessWidget {
  const DashboardHomeTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();

    return RefreshIndicator(
      onRefresh: ctrl.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LocationPill(),
            const SizedBox(height: 16),
            Obx(() {
              if (ctrl.isLoading.value && ctrl.dashboard.value == null) {
                return const DashboardSkeleton();
              }

              final data = ctrl.dashboard.value;
              if (data == null) {
                return _DashboardError(
                  message: ctrl.fetchError.value ?? 'dashboard_loadError'.tr,
                  onRetry: ctrl.load,
                );
              }

              final live = data.markets
                  .where((m) => m.enabled)
                  .toList(growable: false);
              final hero = live.isNotEmpty ? live.first : null;
              // The 2nd live market rides beside the hero (matching the
              // reference layout); anything past that wraps into its own
              // grid below — not a case we hit today (only Food +
              // Cosmetics are live), but keeps this from breaking if a
              // 3rd market goes live before this screen is revisited.
              final beside = live.length > 1 ? live[1] : null;
              final extra = live.length > 2
                  ? live.skip(2).toList(growable: false)
                  : const [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ctrl.isFromCache.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: StaleBanner(onRefresh: ctrl.load),
                      ),
                    ),
                  if (hero != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: beside != null ? 3 : 5,
                          child: HeroMarketTile(
                            market: hero,
                            height: DashboardHomeTiles._heroRowHeight,
                            onTap: () => ctrl.onTileTap(hero.key),
                          ),
                        ),
                        if (beside != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SecondaryMarketTile(
                              market: beside,
                              height: DashboardHomeTiles._heroRowHeight,
                              onTap: () => ctrl.onTileTap(beside.key),
                            ),
                          ),
                        ],
                      ],
                    ),
                  if (extra.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _TileGrid(
                      children: extra
                          .map(
                            (m) => MarketTile(
                              icon: Icons.storefront_rounded,
                              label: marketLabel(m.key, m.label),
                              onTap: () => ctrl.onTileTap(m.key),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (data.comingSoon.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _ComingSoonPanel(
                      entries: data.comingSoon,
                      onTap: ctrl.showComingSoonSheet,
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  static const _heroRowHeight = 190.0;
}

/// The location picker — previously the right-hand half of _TopBar, whose
/// left half (brand name) is now redundant with the shell AppBar's own
/// greeting/title, so only this survives as body content.
class _LocationPill extends StatelessWidget {
  const _LocationPill();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'dashboard_setYourArea'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column grid for any live markets beyond the hero+beside pair, and for
/// coming-soon tiles — wraps to as many rows as needed.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final hasSecond = i + 1 < children.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < children.length ? 12 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 12),
                Expanded(child: hasSecond ? children[i + 1] : const SizedBox()),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// The greyed-out "Coming soon" section — a distinct shaded panel (rather
/// than plain inline tiles) so it visually reads as a different tier from
/// the live markets above it.
class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({required this.entries, required this.onTap});

  final List<DashboardComingSoonEntry> entries;
  final void Function(String label) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dashboard_comingSoon'.tr.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.gray500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          _TileGrid(
            children: entries
                .map(
                  (c) => MarketTile.comingSoon(
                    marketKey: c.key,
                    label: marketLabel(c.key, c.label),
                    onTap: () => onTap(marketLabel(c.key, c.label)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 52,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          CustomDynamicButton(
            label: 'dashboard_tryAgain'.tr,
            icon: Icons.refresh_rounded,
            variant: CustomButtonVariant.outlined,
            accentColor: AppColors.primary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
