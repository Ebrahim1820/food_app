import 'package:flutter/material.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:food_app/services/push_notification_service.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Push Notifications Screen
//
// Sections:
//   • Device   – per-device push toggle (PushNotificationService / PATCH /device-tokens/{id})
//   • Orders   – real-time order alerts (BpNotifPrefsController)
//   • Reviews  – rating alerts
//   • Marketing – promotions and growth tips
//   • System   – maintenance and app updates
//
// Save button PATCHes /business-partners/me/notification-preferences for all
// non-device toggles. The device toggle is saved immediately on change.
// ---------------------------------------------------------------------------

class BusinessNotificationsScreen extends StatelessWidget {
  const BusinessNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BpNotifPrefsController>();
    final push = Get.find<PushNotificationService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          BusinessNotifStrings.appBarTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => CustomDynamicButton(
              label: ctrl.isSaving.value
                  ? BusinessNotifStrings.savingAction
                  : BusinessNotifStrings.saveAction,
              onPressed: ctrl.isSaving.value ? null : ctrl.save,
              variant: CustomButtonVariant.text,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // ── Save reminder ───────────────────────────────────────────────
              _SaveBanner(BusinessNotifStrings.saveBanner),
              const SizedBox(height: 4),

              // ── Device ─────────────────────────────────────────────────────
              _NotifSection(
                icon: Icons.phone_android_outlined,
                color: AppColors.primary,
                label: BusinessNotifStrings.sectionDevice,
                tiles: [
                  _NotifTile(
                    title: BusinessNotifStrings.pushEnabledTitle,
                    subtitle: BusinessNotifStrings.pushEnabledSubtitle,
                    value: push.pushEnabled.value,
                    onChanged: (v) => push.setPushEnabled(v).catchError((_) {}),
                  ),
                ],
              ),

              // ── Orders ──────────────────────────────────────────────────────
              _NotifSection(
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
                label: BusinessNotifStrings.sectionOrders,
                tiles: [
                  _NotifTile(
                    title: BusinessNotifStrings.newOrderTitle,
                    subtitle: BusinessNotifStrings.newOrderSubtitle,
                    value: ctrl.notifyNewOrder.value,
                    onChanged: (v) => ctrl.notifyNewOrder.value = v,
                  ),
                  _NotifTile(
                    title: BusinessNotifStrings.orderReadyTitle,
                    subtitle: BusinessNotifStrings.orderReadySubtitle,
                    value: ctrl.notifyOrderReady.value,
                    onChanged: (v) => ctrl.notifyOrderReady.value = v,
                  ),
                  _NotifTile(
                    title: BusinessNotifStrings.orderCancelledTitle,
                    subtitle: BusinessNotifStrings.orderCancelledSubtitle,
                    value: ctrl.notifyOrderCancelled.value,
                    onChanged: (v) => ctrl.notifyOrderCancelled.value = v,
                  ),
                ],
              ),

              // ── Reviews ─────────────────────────────────────────────────────
              _NotifSection(
                icon: Icons.star_outline_rounded,
                color: AppColors.warningDark,
                label: BusinessNotifStrings.sectionReviews,
                tiles: [
                  _NotifTile(
                    title: BusinessNotifStrings.newReviewTitle,
                    subtitle: BusinessNotifStrings.newReviewSubtitle,
                    value: ctrl.notifyNewReview.value,
                    onChanged: (v) => ctrl.notifyNewReview.value = v,
                  ),
                  _NotifTile(
                    title: BusinessNotifStrings.reviewReplyTitle,
                    subtitle: BusinessNotifStrings.reviewReplySubtitle,
                    value: ctrl.notifyReviewReply.value,
                    onChanged: (v) => ctrl.notifyReviewReply.value = v,
                  ),
                ],
              ),

              // ── Marketing ────────────────────────────────────────────────────
              _NotifSection(
                icon: Icons.campaign_outlined,
                color: AppColors.purple,
                label: BusinessNotifStrings.sectionMarketing,
                tiles: [
                  _NotifTile(
                    title: BusinessNotifStrings.promotionsTitle,
                    subtitle: BusinessNotifStrings.promotionsSubtitle,
                    value: ctrl.notifyPromotions.value,
                    onChanged: (v) => ctrl.notifyPromotions.value = v,
                  ),
                  _NotifTile(
                    title: BusinessNotifStrings.growthTipsTitle,
                    subtitle: BusinessNotifStrings.growthTipsSubtitle,
                    value: ctrl.notifyGrowthTips.value,
                    onChanged: (v) => ctrl.notifyGrowthTips.value = v,
                  ),
                ],
              ),

              // ── System ───────────────────────────────────────────────────────
              _NotifSection(
                icon: Icons.settings_outlined,
                color: AppColors.gray500,
                label: BusinessNotifStrings.sectionSystem,
                tiles: [
                  _NotifTile(
                    title: BusinessNotifStrings.maintenanceTitle,
                    subtitle: BusinessNotifStrings.maintenanceSubtitle,
                    value: ctrl.notifyMaintenanceAlerts.value,
                    onChanged: (v) => ctrl.notifyMaintenanceAlerts.value = v,
                  ),
                  _NotifTile(
                    title: BusinessNotifStrings.appUpdatesTitle,
                    subtitle: BusinessNotifStrings.appUpdatesSubtitle,
                    value: ctrl.notifyAppUpdates.value,
                    onChanged: (v) => ctrl.notifyAppUpdates.value = v,
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A labelled group of notification toggles
// ---------------------------------------------------------------------------
class _NotifSection extends StatelessWidget {
  const _NotifSection({
    required this.icon,
    required this.color,
    required this.label,
    required this.tiles,
  });

  final IconData icon;
  final Color color;
  final String label;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: tiles),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// A single toggle row inside a section card
// ---------------------------------------------------------------------------
class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          height: 1.4,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info banner reminding the user to tap Save
// ---------------------------------------------------------------------------
class _SaveBanner extends StatelessWidget {
  const _SaveBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.infoDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoDark.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.infoDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.infoDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
