import 'package:flutter/material.dart';
import 'package:food_app/bindings/initial_binding.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/screens/auth/keycloak_auth_service.dart';
import 'package:food_app/network/api_service.dart';
import 'package:food_app/services/change_password_service.dart';
import 'package:food_app/strings/change_password_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/address_widgets.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

/// Shows the change-password bottom sheet.
/// On success it logs the user out and returns them to the login screen.
void showChangePasswordSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _loading = false;
  String? _confirmError;

  // Live rule tracking
  bool get _hasLength => _newCtrl.text.length >= 8;
  bool get _hasUpper => _newCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _newCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _newCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;/]'));
  bool get _allRulesMet => _hasLength && _hasUpper && _hasNumber && _hasSpecial;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _confirmError = null);

    if (!_allRulesMet) {
      AppSnackbar.error(
        ChangePasswordStrings.weakTitle,
        ChangePasswordStrings.weakBody,
      );
      return;
    }

    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _confirmError = ChangePasswordStrings.mismatch);
      return;
    }

    setState(() => _loading = true);
    try {
      await ChangePasswordService(
        Get.find<ApiService>(),
      ).changePassword(_newCtrl.text);

      if (!mounted) return;
      Navigator.of(context).pop();

      AppSnackbar.success(
        ChangePasswordStrings.successTitle,
        ChangePasswordStrings.successBody,
        duration: const Duration(seconds: 3),
      );

      await Get.find<KeycloakAuthService>().logout();
      await Get.find<AuthController>().logout();
      Get.offAllNamed(AppRoutes.login);
      InitialBinding.clearUserControllers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.error(
        ChangePasswordStrings.errorTitle,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // viewInsets.bottom = keyboard height (non-zero when keyboard is open)
    // padding.bottom    = system nav bar / safe-area (non-zero when keyboard is hidden)
    // combining both covers all cases: keyboard up OR gesture nav bar present
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom + 28;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),

            Text(
              ChangePasswordStrings.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ChangePasswordStrings.subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // New password field
            _PasswordField(
              controller: _newCtrl,
              label: ChangePasswordStrings.newField,
              obscure: _newObscure,
              onToggle: () => setState(() => _newObscure = !_newObscure),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Confirm password field
            _PasswordField(
              controller: _confirmCtrl,
              label: ChangePasswordStrings.confirmField,
              obscure: _confirmObscure,
              onToggle: () =>
                  setState(() => _confirmObscure = !_confirmObscure),
              onChanged: (_) => setState(() => _confirmError = null),
              errorText: _confirmError,
            ),
            const SizedBox(height: 16),

            // Live validation rules
            _RuleRow(met: _hasLength, label: ChangePasswordStrings.rule8chars),
            const SizedBox(height: 4),
            _RuleRow(met: _hasUpper, label: ChangePasswordStrings.ruleUpper),
            const SizedBox(height: 4),
            _RuleRow(met: _hasNumber, label: ChangePasswordStrings.ruleNumber),
            const SizedBox(height: 4),
            _RuleRow(
              met: _hasSpecial,
              label: ChangePasswordStrings.ruleSpecial,
            ),
            const SizedBox(height: 24),

            CustomDynamicButton(
              label: ChangePasswordStrings.button,
              fullWidth: true,
              isLoading: _loading,
              accentColor: _allRulesMet ? AppColors.primary : AppColors.gray200,
              onPressed: !_allRulesMet ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.gray400,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: met ? AppColors.successDark : AppColors.gray200,
          ),
          child: Icon(
            met ? Icons.check : Icons.remove,
            size: 12,
            color: met ? AppColors.white : AppColors.gray400,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: met ? AppColors.successDark : AppColors.textMuted,
            fontWeight: met ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
