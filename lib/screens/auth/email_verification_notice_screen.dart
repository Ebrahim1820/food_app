import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/services/user_service.dart';
import 'package:food_app/strings/auth_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

/// Shown immediately after successful registration.
///
/// Polls GET /check-verification?email=x (public, no auth) every 5 seconds.
/// When the backend confirms the email is verified (from any device), the
/// screen transitions automatically and navigates to login.
class EmailVerificationNoticeScreen extends StatefulWidget {
  const EmailVerificationNoticeScreen({super.key});

  @override
  State<EmailVerificationNoticeScreen> createState() =>
      _EmailVerificationNoticeScreenState();
}

class _EmailVerificationNoticeScreenState
    extends State<EmailVerificationNoticeScreen> {
  late final String _email;
  late final UserService _userService;

  Timer? _pollTimer;
  bool _verified = false;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _email = (Get.arguments as String?) ?? '';
    _userService = Get.find<UserService>();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_verified) _poll();
    });
  }

  Future<void> _poll() async {
    if (_polling || _verified) return;
    _polling = true;
    try {
      final isVerified = await _userService.checkVerificationByEmail(_email);
      if (isVerified && mounted) {
        _pollTimer?.cancel();
        setState(() => _verified = true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _navigateToLogin(showSuccess: true);
      }
    } finally {
      _polling = false;
    }
  }

  void _navigateToLogin({bool showSuccess = false}) {
    if (showSuccess) {
      AppSnackbar.success(
        EmailVerifNoticeStrings.verifiedTitle,
        EmailVerifNoticeStrings.verifiedSnackbar,
        duration: const Duration(seconds: 3),
      );
    }
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _verified
                    ? Container(
                        key: const ValueKey('verified'),
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: AppColors.successLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          size: 44,
                          color: AppColors.successDark,
                        ),
                      )
                    : Container(
                        key: const ValueKey('waiting'),
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          size: 44,
                          color: AppColors.warningDark,
                        ),
                      ),
              ),

              const SizedBox(height: 28),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _verified
                      ? EmailVerifNoticeStrings.verifiedTitle
                      : EmailVerifNoticeStrings.waitingTitle,
                  key: ValueKey(_verified),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _verified
                    ? EmailVerifNoticeStrings.readySigningIn
                    : EmailVerifNoticeStrings.sentTo,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),

              if (!_verified) ...[
                const SizedBox(height: 6),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  EmailVerifNoticeStrings.hint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      EmailVerifNoticeStrings.waiting,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              if (!_verified) ...[
                _ResendButton(email: _email),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _verified
                      ? () => _navigateToLogin(showSuccess: false)
                      : () => _navigateToLogin(showSuccess: false),
                  style: FilledButton.styleFrom(
                    backgroundColor: _verified
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _verified
                        ? EmailVerifNoticeStrings.signInVerified
                        : EmailVerifNoticeStrings.signInManual,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResendButton extends StatefulWidget {
  final String email;
  const _ResendButton({required this.email});

  @override
  State<_ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<_ResendButton> {
  bool _isSending = false;

  Future<void> _resend() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await Get.find<UserService>().resendVerificationEmail(widget.email);
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isSending ? null : _resend,
        icon: _isSending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(
          EmailVerifNoticeStrings.resend,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
