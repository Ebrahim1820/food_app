import 'package:flutter/material.dart';
import 'package:food_app/controllers/register_controller.dart';
import 'package:food_app/models/dashboard_model.dart';
import 'package:food_app/strings/auth_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/address_widgets.dart';
import 'package:food_app/widgets/app_widgets.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _businessName = TextEditingController();

  // Address fields
  String _addressLabel = 'home';
  Worker? _typeWorker;
  final _street = TextEditingController();
  final _street2 = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();
  final _countryCode = TextEditingController();

  final RegisterController _c = Get.isRegistered<RegisterController>()
      ? Get.find<RegisterController>()
      : Get.put(RegisterController());

  @override
  void initState() {
    super.initState();
    // Clear the server error for a field as soon as the user starts typing.
    _name.addListener(() => _c.clearFieldError('fullName'));
    _email.addListener(() => _c.clearFieldError('email'));
    _password.addListener(() => _c.clearFieldError('password'));
    _businessName.addListener(() => _c.clearFieldError('businessName'));
    _typeWorker = ever(_c.accountType, (_) {
      if (mounted)
        setState(() => _addressLabel = _c.isBusiness ? 'work' : 'home');
    });
  }

  @override
  void dispose() {
    _typeWorker?.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _businessName.dispose();
    _street.dispose();
    _street2.dispose();
    _city.dispose();
    _postalCode.dispose();
    _country.dispose();
    _countryCode.dispose();
    super.dispose();
  }

  // ── Client-side validators ──────────────────────────────────────────────

  String? _validateName(String? v) {
    final serverErr = _c.fieldErrors.value['fullName'];
    if (serverErr != null) return serverErr;
    if (v == null || v.trim().isEmpty) return RegisterStrings.errNameRequired;
    return null;
  }

  String? _validateEmail(String? v) {
    final serverErr = _c.fieldErrors.value['email'];
    if (serverErr != null) return serverErr;
    if (v == null || v.trim().isEmpty) return RegisterStrings.errEmailRequired;
    final hasAt = v.contains('@');
    final hasDot = v.split('@').lastOrNull?.contains('.') ?? false;
    if (!hasAt || !hasDot) return RegisterStrings.errEmailInvalid;
    return null;
  }

  String? _validatePassword(String? v) {
    final serverErr = _c.fieldErrors.value['password'];
    if (serverErr != null) return serverErr;
    if (v == null || v.isEmpty) return RegisterStrings.errPasswordRequired;
    if (v.length < 8) return RegisterStrings.errPasswordLength;
    if (!v.contains(RegExp(r'[A-Z]'))) return RegisterStrings.errPasswordUpper;
    if (!v.contains(RegExp(r'[a-z]'))) return RegisterStrings.errPasswordLower;
    if (!v.contains(RegExp(r'[0-9]'))) return RegisterStrings.errPasswordNumber;
    return null;
  }

  String? _validateBusinessName(String? v) {
    final serverErr = _c.fieldErrors.value['businessName'];
    if (serverErr != null) return serverErr;
    if (_c.isBusiness && (v == null || v.trim().isEmpty)) {
      return RegisterStrings.errBusinessNameRequired;
    }
    return null;
  }

  String? _validateMarket() {
    final serverErr = _c.fieldErrors.value['market'];
    if (serverErr != null) return serverErr;
    if (_c.isBusiness && _c.selectedMarket.value == null) {
      return 'Please choose which market this business belongs to.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_validateMarket() != null) {
      setState(() {}); // re-render so the market error text shows
      return;
    }
    await _c.submit(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      businessName: _businessName.text.trim(),
      address: {
        'label': _addressLabel,
        'street': _street.text.trim(),
        if (_street2.text.trim().isNotEmpty) 'street2': _street2.text.trim(),
        'city': _city.text.trim(),
        'postalCode': _postalCode.text.trim(),
        'country': _country.text.trim(),
        'countryCode': _countryCode.text.trim().toUpperCase(),
      },
    );
    // Re-run validation after submit so server-side field errors appear immediately.
    if (mounted && _c.fieldErrors.value.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icon/perka_mark_dark.png',
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AuthStrings.appBrandName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  RegisterStrings.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  RegisterStrings.subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),

                // ── Account type selector ───────────────────────────────
                Text(
                  RegisterStrings.iWantTo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _AccountTypeCard(
                          icon: Icons.fastfood_outlined,
                          title: RegisterStrings.orderFood,
                          subtitle: RegisterStrings.orderFoodSubtitle,
                          selected: !_c.isBusiness,
                          onTap: () => _c.selectType('user'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccountTypeCard(
                          icon: Icons.storefront_outlined,
                          title: RegisterStrings.sellFood,
                          subtitle: RegisterStrings.sellFoodSubtitle,
                          selected: _c.isBusiness,
                          onTap: () => _c.selectType('business'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Business name (business accounts only) ──────────────
                Obx(
                  () => _c.isBusiness
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AppTextField(
                            label: RegisterStrings.businessName,
                            hint: RegisterStrings.businessNameHint,
                            icon: Icons.store_mall_directory_outlined,
                            controller: _businessName,
                            textInputAction: TextInputAction.next,
                            validator: _validateBusinessName,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Business market (business accounts only) ────────────
                // Options come from GET /dashboard's businessRegistrationEnabled
                // markets — today just Food. Grows automatically with zero
                // UI changes once another market opens for registration.
                Obx(
                  () => _c.isBusiness
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MarketDropdown(
                            markets: _c.businessMarkets,
                            selected: _c.selectedMarket.value,
                            error: _validateMarket(),
                            onChanged: (key) => _c.selectMarket(key),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                AppTextField(
                  label: RegisterStrings.fullName,
                  hint: RegisterStrings.fullNameHint,
                  icon: Icons.person_outline,
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: AuthStrings.email,
                  hint: 'you@email.com',
                  icon: Icons.mail_outline,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: RegisterStrings.phone,
                  hint: RegisterStrings.phoneHint,
                  icon: Icons.phone_outlined,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                // ── Address section — label/options differ by account type ──
                Obx(() {
                  final isBusiness = _c.isBusiness;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBusiness
                            ? RegisterStrings.businessAddress
                            : RegisterStrings.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBusiness
                            ? RegisterStrings.businessAddressSubtitle
                            : RegisterStrings.deliveryAddressSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AddressLabelSelector(
                        options: isBusiness
                            ? [
                                (
                                  value: 'work',
                                  label: RegisterStrings.addrOffice,
                                  icon: Icons.work_rounded,
                                ),
                                (
                                  value: 'branch',
                                  label: RegisterStrings.addrBranch,
                                  icon: Icons.storefront_rounded,
                                ),
                                (
                                  value: 'other',
                                  label: RegisterStrings.addrOther,
                                  icon: Icons.location_on_rounded,
                                ),
                              ]
                            : [
                                (
                                  value: 'home',
                                  label: RegisterStrings.addrHome,
                                  icon: Icons.home_rounded,
                                ),
                                (
                                  value: 'work',
                                  label: RegisterStrings.addrWork,
                                  icon: Icons.work_rounded,
                                ),
                                (
                                  value: 'other',
                                  label: RegisterStrings.addrOther,
                                  icon: Icons.location_on_rounded,
                                ),
                              ],
                        selected: _addressLabel,
                        onChanged: (v) => setState(() => _addressLabel = v),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                AddressFormField(
                  controller: _street,
                  label: RegisterStrings.street,
                  required: true,
                ),
                const SizedBox(height: 10),
                AddressFormField(
                  controller: _street2,
                  label: RegisterStrings.street2,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AddressFormField(
                        controller: _city,
                        label: RegisterStrings.city,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: AddressFormField(
                        controller: _postalCode,
                        label: RegisterStrings.postcode,
                        required: true,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AddressFormField(
                        controller: _country,
                        label: RegisterStrings.country,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: AddressFormField(
                        controller: _countryCode,
                        label: RegisterStrings.countryCode,
                        required: true,
                        maxLength: 2,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 24),

                AppTextField(
                  label: AuthStrings.password,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  controller: _password,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),
                const _PasswordRulesHint(),
                const SizedBox(height: 24),

                // ── Submit button ───────────────────────────────────────
                // Wrapping in Obx so it re-validates when server errors arrive.
                Obx(() {
                  _c.fieldErrors.value; // track for rebuild
                  return PrimaryButton(
                    label: _c.isBusiness
                        ? RegisterStrings.submitBusiness
                        : RegisterStrings.submitUser,
                    loading: _c.isLoading.value,
                    onPressed: _submit,
                  );
                }),
                const SizedBox(height: 14),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text.rich(
                      TextSpan(
                        text: RegisterStrings.termsPrefix,
                        style: const TextStyle(
                          color: AppColors.hint,
                          fontSize: 12,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: RegisterStrings.terms,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: RegisterStrings.privacyPolicy,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Text.rich(
                      TextSpan(
                        text: RegisterStrings.haveAccount,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: AuthStrings.signIn,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
}

// ── Password rules hint shown below the password field ──────────────────────
class _PasswordRulesHint extends StatelessWidget {
  const _PasswordRulesHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      RegisterStrings.passwordRules,
      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    );
  }
}

// ── Account type card ────────────────────────────────────────────────────────
class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.hint,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.ink,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Business market dropdown ─────────────────────────────────────────────────
class _MarketDropdown extends StatelessWidget {
  const _MarketDropdown({
    required this.markets,
    required this.selected,
    required this.error,
    required this.onChanged,
  });

  final List<DashboardMarket> markets;
  final String? selected;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Which market is this business in?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.field,
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: AppColors.hint,
            ),
            hintText: markets.isEmpty
                ? 'Loading markets…'
                : 'Select a market',
            hintStyle: const TextStyle(color: AppColors.hint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            errorText: error,
          ),
          items: markets
              .map(
                (m) => DropdownMenuItem(value: m.key, child: Text(m.label)),
              )
              .toList(),
          onChanged: markets.isEmpty
              ? null
              : (value) {
                  if (value != null) onChanged(value);
                },
        ),
      ],
    );
  }
}
