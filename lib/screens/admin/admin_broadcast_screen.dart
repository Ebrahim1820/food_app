// lib/screens/admin/admin_broadcast_screen.dart
//
// Admin-only "send a push to every customer right now" form — the frontend
// surface for POST /admin/notifications/broadcast. Fire-once-now by design;
// no scheduling UI (that needs a backend way to target inactive users,
// which doesn't exist yet — separate future work).

import 'package:flutter/material.dart';
import 'package:food_app/controllers/admin_controller.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/widgets/common/confirm_dialog.dart';
import 'package:food_app/widgets/dialog/info_dialog.dart';
import 'package:get/get.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _ctrl = Get.find<AdminController>();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  static const _titleMaxLen = 65;
  static const _bodyMaxLen = 240;

  @override
  void initState() {
    super.initState();
    // Defensive client-side gate — the backend already rejects non-admins
    // with 403, but the entry point should never even be reachable, and if
    // it somehow is (deep link, stale nav state), bounce immediately rather
    // than let the form render and fail on submit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.find<AuthController>().isAdmin) Get.back();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.campaign_rounded,
      title: 'Send to All Customers?',
      body:
          'This sends a push notification to every customer immediately — '
          'there is no undo and no scheduling. Double-check the wording '
          'before sending.',
      confirmLabel: 'Yes, Send Now',
      cancelLabel: 'Cancel',
      dangerColor: AppColors.accentDark,
      dangerLightColor: AppColors.accentLight,
    );
    if (confirmed != true) return;

    final count = await _ctrl.sendBroadcast(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
    );

    if (!mounted) return;

    if (count != null) {
      await InfoDialog.show(
        context,
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: 'Broadcast Sent',
        body: 'Delivered to $count customer${count == 1 ? '' : 's'}.',
        buttonLabel: 'Done',
      );
      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
      }
    } else {
      AppSnackbar.error(
        'adminBroadcast_failedTitle'.tr,
        'adminBroadcast_failedBody'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Send Broadcast',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, safe.bottom + 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.infoDark.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.infoDark,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Sends immediately to every customer — fire-once-now, '
                          'no scheduling and no way to target a smaller '
                          'audience yet.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.infoDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Title',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  maxLength: _titleMaxLen,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'e.g. Good food is going to waste',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Body',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bodyCtrl,
                  maxLength: _bodyMaxLen,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: _fieldDecoration(
                    'e.g. Check what\'s nearby and rescue a surprise meal today',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Body is required'
                      : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Obx(
                    () => FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _ctrl.isSendingBroadcast.value ? null : _send,
                      icon: _ctrl.isSendingBroadcast.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _ctrl.isSendingBroadcast.value
                            ? 'Sending…'
                            : 'Send to All Customers',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
