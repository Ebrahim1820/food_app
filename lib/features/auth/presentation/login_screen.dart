import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/features/auth/models/user_model.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'auth_provider.dart';
import 'register_screen.dart'; // for navigation

// Add this provider (insert after imports)
final selectedPlatformProvider = StateProvider<String>((ref) => 'Customer');

/// Login screen.
///
/// Flow:
///   Enter email + password → tap "Sign in"
///   → AuthNotifier.login() → on success router redirects based on role:
///       customer  → /listings
///       business  → /bp/dashboard
///       admin     → /admin (future)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    // Navigation is handled by the listener below (router redirect on state change)
  }

  
  void _navigateBasedOnRole(UserModel user) {
    if (!mounted) return;
    if (user.isBusinessPartner) {
      context.go('/bp/dashboard');
    } else {
      context.go('/listings');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to navigate or show errors
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        _navigateBasedOnRole(next.user);
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage =
        authState is AuthError ? authState.message : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),

                // ── Logo / Brand mark ─────────────────────────────────────
                _BrandHeader(),

                const SizedBox(height: 40),

                // ── Heading ───────────────────────────────────────────────
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to find surplus food near you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // ── Error banner ──────────────────────────────────────────
                if (errorMessage != null) ...[
                  ErrorBanner(errorMessage),
                  const SizedBox(height: 16),
                ],

                // ── Email ─────────────────────────────────────────────────
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus,
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────────────────
                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  focusNode: _passwordFocus,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your password.';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),

                // ── Forgot password ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO(MVP): add forgot password screen in Phase 2
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Password reset will be available soon.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Sign in button ────────────────────────────────────────
                AppButton(
                  label: 'Sign in',
                  onPressed: _submit,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────────────────────
                const _OrDivider(),

                const SizedBox(height: 24),

                // ── Dev shortcuts (mock only, remove in production) ───────
                const _DevShortcuts(),

                const SizedBox(height: 32),

                // ── Register link ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push(RegisterScreen.routePath),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'FoodRescue',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _OrDivider extends ConsumerWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(selectedPlatformProvider);
    return Row(
      children: [
        const Expanded(
            child: Divider(color: AppColors.border, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            // Show platform instead of static text
            'Platform: $platform',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 12),
          ),
        ),
        const Expanded(
            child: Divider(color: AppColors.border, thickness: 0.5)),
      ],
    );
  }
}

/// Quick-fill buttons for testing during development.
/// Remove this widget before going to production.
class _DevShortcuts extends ConsumerWidget {
  const _DevShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Only show in debug mode
    assert(() {
      return true;
    }());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.warning.withOpacity(0.4), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛠 Dev shortcuts (remove before release)',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _DevChip(
                label: 'Login as Customer',
                onTap: () { 
                   // set selected platform for UI
                  ref.read(selectedPlatformProvider.notifier).state = 'Customer';
                  ref.read(authProvider.notifier).login(
                      email: 'customer@test.com',
                      password: 'password',
                    );
                    },
              ),
              _DevChip(
                label: 'Login as Business',
                onTap: ()  {
                  // set selected platform for UI
                  ref.read(selectedPlatformProvider.notifier).state = 'Business';
                  // perform login
                  ref.read(authProvider.notifier).login(
                        email: 'business@test.com',
                        password: 'password',
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevChip extends StatelessWidget {
  const _DevChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.warning,
          ),
        ),
      ),
    );
  }
}
