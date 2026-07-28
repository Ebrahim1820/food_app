import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

/// Reusable banner shown whenever the signed-in user has not yet verified
/// their email address. Place it inside an [Obx] at the call site so it
/// appears/disappears reactively.
///
/// Usage:
/// ```dart
/// Obx(() {
///   final user = orderCtrl.currentUser.value;
///   if (user == null || user.isVerified) return const SizedBox.shrink();
///   return EmailVerificationBannerWidget(
///     email: user.email,
///     onResend: () => userService.resendVerificationEmail(user.email),
///   );
/// })
/// ```
///
/// [onResend] is an async function that makes the API call.
/// The widget handles loading state and success/error snackbars internally.
/// Pass `null` to hide the resend button.
class EmailVerificationBannerWidget extends StatefulWidget {
  final String email;
  final Future<void> Function()? onResend;

  const EmailVerificationBannerWidget({
    super.key,
    required this.email,
    this.onResend,
  });

  @override
  State<EmailVerificationBannerWidget> createState() =>
      _EmailVerificationBannerWidgetState();
}

class _EmailVerificationBannerWidgetState
    extends State<EmailVerificationBannerWidget> {
  bool _isSending = false;

  Future<void> _handleResend() async {
    if (_isSending || widget.onResend == null) return;
    setState(() => _isSending = true);
    try {
      await widget.onResend!();
      if (!mounted) return;
      AppSnackbar.success('', 'emailVerif_resendSuccess'.tr);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error('', 'emailVerif_resendError'.tr);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.warningDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'emailVerif_title'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'emailVerif_body'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.warningDark.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warningDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.onResend != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: _isSending ? null : _handleResend,
                icon: _isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.warningDark,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  'emailVerif_resend'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warningDark,
                  side: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
