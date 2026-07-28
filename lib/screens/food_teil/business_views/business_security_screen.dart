import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:core/core.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/dialog/change_password_sheet.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Security Screen
//
// Covers password management, two-factor authentication (2FA), and
// a danger-zone section for account deletion.
//
// All actions are stubs for now — connect to your Keycloak / backend APIs
// when implementing each feature.
// ---------------------------------------------------------------------------

class BusinessSecurityScreen extends StatefulWidget {
  const BusinessSecurityScreen({super.key});

  @override
  State<BusinessSecurityScreen> createState() => _BusinessSecurityScreenState();
}

class _BusinessSecurityScreenState extends State<BusinessSecurityScreen> {
  // Whether the user has 2FA enabled (would be fetched from backend)
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
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
          BusinessSecurityStrings.appBarTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // ── Password ──────────────────────────────────────────────────────
            _SectionLabel(BusinessSecurityStrings.sectionPassword),
            _SecurityCard(
              children: [
                _ActionTile(
                  icon: Icons.lock_outline,
                  iconColor: AppColors.infoDark,
                  title: BusinessSecurityStrings.changePasswordTitle,
                  subtitle: BusinessSecurityStrings.changePasswordSubtitle,
                  onTap: () => showChangePasswordSheet(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Two-Factor Authentication ─────────────────────────────────────
            // 2FA adds a one-time code (via SMS or an authenticator app) as a
            // second step after entering the password.
            _SectionLabel(BusinessSecurityStrings.section2fa),
            _SecurityCard(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.purple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    BusinessSecurityStrings.twoFaTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    _twoFactorEnabled
                        ? BusinessSecurityStrings.twoFaActiveSubtitle
                        : BusinessSecurityStrings.twoFaOffSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _twoFactorEnabled
                          ? AppColors.successDark
                          : AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: _twoFactorEnabled,
                    onChanged: (v) {
                      setState(() => _twoFactorEnabled = v);
                      if (v) {
                        AppSnackbar.success(
                          BusinessSecurityStrings.twoFaEnabledSnack,
                          BusinessSecurityStrings.twoFaEnabledBody,
                        );
                      } else {
                        AppSnackbar.warning(
                          BusinessSecurityStrings.twoFaDisabledSnack,
                          BusinessSecurityStrings.twoFaDisabledBody,
                        );
                      }
                    },
                    activeThumbColor: AppColors.white,
                    activeTrackColor: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Active Sessions ───────────────────────────────────────────────
            // Shows where the user is currently logged in so they can revoke
            // access from unknown devices.
            _SectionLabel(BusinessSecurityStrings.sectionActiveSessions),
            _SecurityCard(
              children: [
                _SessionTile(
                  device: 'iPhone 15 Pro',
                  location: 'Berlin, Germany',
                  time: 'Active now',
                  isCurrent: true,
                ),
                const Divider(height: 1, indent: 60, color: AppColors.divider),
                _SessionTile(
                  device: 'MacBook Pro',
                  location: 'Munich, Germany',
                  time: '2 hours ago',
                  isCurrent: false,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Danger Zone ───────────────────────────────────────────────────
            // Destructive actions that cannot be undone — shown clearly separated
            // with a red border so users don't tap them accidentally.
            _SectionLabel(BusinessSecurityStrings.sectionDangerZone),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.errorLight, width: 1.5),
              ),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.storefront_outlined,
                    iconColor: AppColors.error,
                    title: BusinessSecurityStrings.closeBusinessTitle,
                    subtitle: BusinessSecurityStrings.closeBusinessSubtitle,
                    titleColor: AppColors.error,
                    onTap: () => _confirmClose(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: 60,
                    color: AppColors.divider,
                  ),
                  _ActionTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: AppColors.error,
                    title: BusinessSecurityStrings.deleteAccountTitle,
                    subtitle: BusinessSecurityStrings.deleteAccountSubtitle,
                    titleColor: AppColors.error,
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete account confirmation dialog ───────────────────────────────────
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          BusinessSecurityStrings.deleteDialogTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          BusinessSecurityStrings.deleteDialogBody,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          CustomDynamicButton(
            label: BusinessSecurityStrings.deleteDialogCancel,
            onPressed: () => Navigator.pop(ctx),
            variant: CustomButtonVariant.text,
            accentColor: AppColors.textMuted,
          ),
          CustomDynamicButton(
            label: BusinessSecurityStrings.deleteDialogConfirm,
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: DELETE /api/users/{id}
            },
            accentColor: AppColors.error,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  // ── Close business confirmation dialog ───────────────────────────────────
  // Requires a non-empty reason (backend rejects the request without one),
  // then calls the real endpoint — unlike delete-account above, which is
  // still a stub pending a separate backend contract.
  void _confirmClose(BuildContext context) {
    final reasonController = TextEditingController();
    final bpCtrl = Get.find<BusinessPartnerController>();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> submit() async {
            final reason = reasonController.text.trim();
            if (reason.isEmpty) {
              setDialogState(() {
                errorText = BusinessSecurityStrings.closeDialogReasonRequired;
              });
              return;
            }
            final ok = await bpCtrl.closeBusiness(reason);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (ok) {
              AppSnackbar.success(
                BusinessSecurityStrings.closeBusinessSuccessSnack,
                BusinessSecurityStrings.closeBusinessSuccessBody,
              );
              Get.offAllNamed(AppRoutes.mainNavigation);
            } else {
              AppSnackbar.error(
                BusinessSecurityStrings.closeBusinessErrorSnack,
                bpCtrl.fetchError.value ?? ErrorStrings.somethingWentWrong,
              );
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              BusinessSecurityStrings.closeDialogTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BusinessSecurityStrings.closeDialogBody,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  onChanged: (_) {
                    if (errorText != null)
                      setDialogState(() => errorText = null);
                  },
                  decoration: InputDecoration(
                    labelText: BusinessSecurityStrings.closeDialogReasonLabel,
                    hintText: BusinessSecurityStrings.closeDialogReasonHint,
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              CustomDynamicButton(
                label: BusinessSecurityStrings.closeDialogCancel,
                onPressed: () => Navigator.pop(ctx),
                variant: CustomButtonVariant.text,
                accentColor: AppColors.textMuted,
              ),
              Obx(
                () => CustomDynamicButton(
                  label: BusinessSecurityStrings.closeDialogConfirm,
                  onPressed: submit,
                  isLoading: bpCtrl.isClosingBusiness.value,
                  accentColor: AppColors.error,
                  borderRadius: 8,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable white card wrapper for a group of security tiles
// ---------------------------------------------------------------------------
class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
    );
  }
}

// A row with a coloured icon, title, subtitle, and a chevron arrow
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor = AppColors.ink,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor,
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
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.gray300,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

// A session row showing device name, location, last-seen time, and a badge
// for the current session
class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.device,
    required this.location,
    required this.time,
    required this.isCurrent,
  });

  final String device;
  final String location;
  final String time;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          device.toLowerCase().contains('mac')
              ? Icons.laptop_mac_outlined
              : Icons.smartphone_outlined,
          color: AppColors.gray600,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            device,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            // Green "This device" badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                BusinessSecurityStrings.sessionCurrentBadge,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.successDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '$location · $time',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          height: 1.4,
        ),
      ),
      trailing: isCurrent
          ? null
          : CustomDynamicButton(
              label: BusinessSecurityStrings.sessionRevokeButton,
              onPressed: () => AppSnackbar.success(
                BusinessSecurityStrings.sessionRevokedSnack,
                BusinessSecurityStrings.sessionRevokedBody,
              ),
              variant: CustomButtonVariant.text,
              accentColor: AppColors.error,
            ),
    );
  }
}

// Small uppercase section label
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.gray400,
        ),
      ),
    );
  }
}
