import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/controllers/dashboard_controller.dart';
import 'package:food_app/widgets/dashboard_icons.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';

/// The "Perka Hub" bottom sheet — opened by the bottom nav's center floating
/// button — lets the user jump straight to the Dashboard's market picker or
/// any live market (Food/Cosmetics/...), without leaving whatever screen
/// they're currently on.
///
/// Reads [DashboardController.dashboard] (the same backend market list the
/// Dashboard screen's own tiles use) and reuses [DashboardController.onTileTap]
/// for navigation, rather than re-deciding customer-vs-business routing here.
class ServiceSwitcherSheet {
  const ServiceSwitcherSheet._();

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDashboardTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _ServiceSwitcherSheetContent(onDashboardTap: onDashboardTap),
    );
  }
}

class _ServiceSwitcherSheetContent extends StatelessWidget {
  const _ServiceSwitcherSheetContent({required this.onDashboardTap});

  final VoidCallback onDashboardTap;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              HubSheetStrings.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              HubSheetStrings.subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            _HubTile(
              icon: Icons.grid_view_rounded,
              color: AppColors.shellBackground,
              label: NavigationBarStrings.dashboard,
              onTap: () {
                Navigator.of(context).pop();
                onDashboardTap();
              },
            ),

            // Only markets the backend currently has enabled — "coming soon"
            // ones (e.g. Clothes today) aren't real destinations yet, so they
            // don't belong in a switcher meant to jump straight there.
            Obx(() {
              final liveMarkets = (ctrl.dashboard.value?.markets ?? const [])
                  .where((m) => m.enabled)
                  .toList();
              if (liveMarkets.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  for (final market in liveMarkets)
                    _HubTile(
                      icon: marketIcon(market.key),
                      color: marketAccent(market.key),
                      label: marketLabel(market.key, market.label),
                      onTap: () {
                        Navigator.of(context).pop();
                        ctrl.onTileTap(market.key);
                      },
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
