import 'package:flutter/material.dart';
import 'package:food_app/controllers/login_controller.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/strings/auth_strings.dart';
import 'package:food_app/widgets/dialog/forgot_password_sheet.dart';
import 'package:get/get.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final LoginController _c = Get.isRegistered<LoginController>()
      ? Get.find<LoginController>()
      : Get.put(LoginController());

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _c.signIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _GreenHeader(
              title: AuthStrings.welcomeBack,
              subtitle: AuthStrings.welcomeBackSubtitle,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: AuthStrings.emailOrUsername,
                      hint: AuthStrings.emailHint,
                      icon: Icons.person_outline,
                      controller: _email,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      ltr: true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? AuthStrings.emailRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: AuthStrings.password,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      controller: _password,
                      obscure: true,
                      ltr: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? AuthStrings.passwordMin
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showForgotPasswordSheet(context),
                        child: Text(
                          AuthStrings.forgotPassword,
                          style: const TextStyle(
                            color: AppColors.primaryDark2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(
                      () => PrimaryButton(
                        label: AuthStrings.signIn,
                        loading: _c.isLoading.value,
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const LabeledDivider(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        SocialButton(
                          label: 'Google',
                          icon: Icons.g_mobiledata,
                          onPressed: () {},
                        ),
                        const SizedBox(width: 12),
                        SocialButton(
                          label: 'Apple',
                          icon: Icons.apple,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: _FooterLink(
                        text: AuthStrings.noAccount,
                        action: AuthStrings.signUp,
                        onTap: () => Get.toNamed(AppRoutes.register),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreenHeader extends StatelessWidget {
  const _GreenHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        width: double.infinity,
        color: AppColors.primaryDark2,
        padding: EdgeInsets.fromLTRB(24, top + 28, 24, 46),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/icon/perka_mark_light.png', height: 26),
                SizedBox(width: 8),
                Text(
                  AuthStrings.appBrandName,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 30)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + 12,
        size.width,
        size.height - 30,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.text,
    required this.action,
    required this.onTap,
  });
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          children: [
            TextSpan(
              text: action,
              style: const TextStyle(
                color: AppColors.primaryDark2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
