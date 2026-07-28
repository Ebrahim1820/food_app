import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// Rounded text field with a leading icon and optional password toggle,
/// matching the Perka look.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.textInputAction,
    this.ltr = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  // Force the field (icon, hint, input) to LTR while the label above it
  // still inherits the ambient direction. Use for email/password fields.
  final bool ltr;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscured,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.hint, fontSize: 14),
        prefixIcon: Icon(widget.icon, color: AppColors.hint, size: 21),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _obscured ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.hint,
                  size: 21,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
        filled: true,
        fillColor: AppColors.field,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border(AppColors.transparent),
        enabledBorder: _border(AppColors.transparent),
        focusedBorder: _border(AppColors.primary),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        widget.ltr
            ? Directionality(textDirection: TextDirection.ltr, child: field)
            : field,
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: color,
      width: color == AppColors.primary ? 1.4 : 1,
    ),
  );
}

/// Big green primary action button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark1,
          foregroundColor: AppColors.white,
          elevation: 0,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Outlined social sign-in button (Google / Apple).
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: AppColors.ink),
          label: Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

/// "or continue with" divider.
class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, this.label = 'or continue with'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.hint, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}
