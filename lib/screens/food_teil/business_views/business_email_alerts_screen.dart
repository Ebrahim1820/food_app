import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/bp_email_prefs_controller.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Email Alerts Screen
//
// Controls which automated emails the business owner receives.
// Grouped into: Reports, Orders, and Reviews.
//
// onInit fetches from GET /business-partners/me/email-preferences.
// Save button PATCHes the same endpoint with all current values.
// ---------------------------------------------------------------------------

class BusinessEmailAlertsScreen extends StatelessWidget {
  const BusinessEmailAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BpEmailPrefsController>();

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
          BusinessEmailStrings.appBarTitle,
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
                  ? BusinessEmailStrings.savingAction
                  : BusinessEmailStrings.saveAction,
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
              _EmailBanner(),

              const SizedBox(height: 12),

              _SaveBanner(BusinessEmailStrings.saveBanner),

              const SizedBox(height: 20),

              _AlertSection(
                icon: Icons.bar_chart_outlined,
                color: AppColors.infoDark,
                label: BusinessEmailStrings.sectionReports,
                tiles: [
                  _AlertTile(
                    title: BusinessEmailStrings.dailySummaryTitle,
                    subtitle: BusinessEmailStrings.dailySummarySubtitle,
                    value: ctrl.emailDailySummary.value,
                    onChanged: (v) => ctrl.emailDailySummary.value = v,
                  ),
                  _AlertTile(
                    title: BusinessEmailStrings.weeklyReportTitle,
                    subtitle: BusinessEmailStrings.weeklyReportSubtitle,
                    value: ctrl.emailWeeklyReport.value,
                    onChanged: (v) => ctrl.emailWeeklyReport.value = v,
                  ),
                  _AlertTile(
                    title: BusinessEmailStrings.monthlyReportTitle,
                    subtitle: BusinessEmailStrings.monthlyReportSubtitle,
                    value: ctrl.emailMonthlyReport.value,
                    onChanged: (v) => ctrl.emailMonthlyReport.value = v,
                  ),
                ],
              ),

              _AlertSection(
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
                label: BusinessEmailStrings.sectionOrders,
                tiles: [
                  _AlertTile(
                    title: BusinessEmailStrings.orderConfirmTitle,
                    subtitle: BusinessEmailStrings.orderConfirmSubtitle,
                    value: ctrl.emailOrderConfirmation.value,
                    onChanged: (v) => ctrl.emailOrderConfirmation.value = v,
                  ),
                  _AlertTile(
                    title: BusinessEmailStrings.refundAlertTitle,
                    subtitle: BusinessEmailStrings.refundAlertSubtitle,
                    value: ctrl.emailRefundAlert.value,
                    onChanged: (v) => ctrl.emailRefundAlert.value = v,
                  ),
                ],
              ),

              _AlertSection(
                icon: Icons.star_outline_rounded,
                color: AppColors.warningDark,
                label: BusinessEmailStrings.sectionReviews,
                tiles: [
                  _AlertTile(
                    title: BusinessEmailStrings.newReviewTitle,
                    subtitle: BusinessEmailStrings.newReviewSubtitle,
                    value: ctrl.emailNewReview.value,
                    onChanged: (v) => ctrl.emailNewReview.value = v,
                  ),
                  _AlertTile(
                    title: BusinessEmailStrings.lowRatingTitle,
                    subtitle: BusinessEmailStrings.lowRatingSubtitle,
                    value: ctrl.emailLowRatingAlert.value,
                    onChanged: (v) => ctrl.emailLowRatingAlert.value = v,
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

// Shows the account email address so the user knows where alerts are sent
class _EmailBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.email_outlined, color: AppColors.infoDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BusinessEmailBannerStrings.bannerLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.infoDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  BusinessEmailBannerStrings.bannerAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.infoDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({
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

class _AlertTile extends StatelessWidget {
  const _AlertTile({
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
