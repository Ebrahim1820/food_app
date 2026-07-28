import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Business Bank Account & Payment Settings Screen
//
// Multi-account CRUD: list view, add/edit bottom sheet, delete with confirm.
// Cash-payment toggle at the bottom.
// ---------------------------------------------------------------------------

class BusinessBankAccountScreen extends StatelessWidget {
  const BusinessBankAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partnerCtrl = Get.find<BusinessPartnerController>();
    if (!Get.isRegistered<BankAccountController>()) {
      Get.put<BankAccountController>(
        BankAccountController(BankAccountService(Get.find<ApiService>())),
        permanent: true,
      );
    }
    final bankCtrl = Get.find<BankAccountController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          BusinessBankAccountScreenStrings.appBarTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (bankCtrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final errorMsg = bankCtrl.errorMessage.value;
          if (errorMsg != null && bankCtrl.accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    size: 48,
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMsg,
                    style: const TextStyle(color: AppColors.gray500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomDynamicButton(
                    label: BusinessBankAccountScreenStrings.retryButton,
                    onPressed: bankCtrl.fetch,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: bankCtrl.fetch,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Bank Accounts Section ──────────────────────────────────
                _SectionHeader(
                  title: BusinessBankAccountScreenStrings.sectionBankAccounts,
                  onAdd: () => _showAccountSheet(context, bankCtrl),
                ),
                const SizedBox(height: 10),

                if (bankCtrl.accounts.isEmpty)
                  _EmptyAccountsState(
                    onAdd: () => _showAccountSheet(context, bankCtrl),
                  )
                else
                  ...bankCtrl.accounts.map(
                    (account) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AccountCard(
                        key: ValueKey(account.id),
                        account: account,
                        ctrl: bankCtrl,
                        onEdit: () => _showAccountSheet(
                          context,
                          bankCtrl,
                          account: account,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Payment Settings Section ───────────────────────────────
                _SectionLabel(
                  BusinessBankAccountScreenStrings.sectionPaymentSettings,
                ),
                _InfoCard(children: [_CashToggleRow(ctrl: partnerCtrl)]),
                const SizedBox(height: 8),
                _HintBanner(
                  icon: Icons.info_outline_rounded,
                  text: BusinessBankAccountScreenStrings.cashHintBanner,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showAccountSheet(
    BuildContext context,
    BankAccountController ctrl, {
    BankAccountModel? account,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountSheet(ctrl: ctrl, existing: account),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header with "Add" action button
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  BusinessBankAccountScreenStrings.addAccountButton,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section label (uppercase small caps)
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyAccountsState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAccountsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 30,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            BusinessBankAccountScreenStrings.emptyTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            BusinessBankAccountScreenStrings.emptySubtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CustomDynamicButton(
            label: BusinessBankAccountScreenStrings.emptyAddButton,
            onPressed: onAdd,
            icon: Icons.add_rounded,
            accentColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bank account card
// ---------------------------------------------------------------------------

class _AccountCard extends StatefulWidget {
  final BankAccountModel account;
  final BankAccountController ctrl;
  final VoidCallback onEdit;

  const _AccountCard({
    super.key,
    required this.account,
    required this.ctrl,
    required this.onEdit,
  });

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.account.isDefault ? 1.0 : 0.0,
    );
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_AccountCard old) {
    super.didUpdateWidget(old);
    if (widget.account.isDefault != old.account.isDefault) {
      widget.account.isDefault ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _maskedIban(String iban) {
    if (iban.isEmpty) return '—';
    final clean = iban.replaceAll(' ', '');
    if (clean.length <= 4) return iban;
    return '•••• ${clean.substring(clean.length - 4)}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          BusinessBankAccountScreenStrings.deleteDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          BusinessBankAccountScreenStrings.deleteDialogBody(
            widget.account.bankName.isNotEmpty
                ? widget.account.bankName
                : widget.account.accountHolderName,
          ),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          CustomDynamicButton(
            label: BusinessBankAccountScreenStrings.deleteDialogCancel,
            onPressed: () => Navigator.pop(ctx, false),
            variant: CustomButtonVariant.text,
            accentColor: AppColors.textSecondary,
          ),
          CustomDynamicButton(
            label: BusinessBankAccountScreenStrings.deleteDialogConfirm,
            onPressed: () => Navigator.pop(ctx, true),
            accentColor: AppColors.error,
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.ctrl.delete(widget.account.id);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final saving = widget.ctrl.isSaving.value;

      return AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final v = _t.value;

          // Interpolate every colour from the single animation value
          final borderColor = Color.lerp(
            AppColors.border,
            AppColors.primary,
            v,
          )!;
          final bgColor = Color.lerp(
            AppColors.white,
            AppColors.primary.withValues(alpha: 0.04),
            v,
          )!;
          final iconBg = Color.lerp(
            AppColors.gray100,
            AppColors.primaryLight,
            v,
          )!;
          final iconColor = Color.lerp(
            AppColors.gray400,
            AppColors.primary,
            v,
          )!;
          final nameColor = Color.lerp(
            AppColors.textPrimary,
            AppColors.primary,
            v,
          )!;
          final radioFill = Color.lerp(
            Colors.transparent,
            AppColors.primary,
            v,
          )!;
          final radioBorder = Color.lerp(
            AppColors.gray300,
            AppColors.primary,
            v,
          )!;

          return GestureDetector(
            onTap: (widget.account.isDefault || saving)
                ? null
                : () =>
                      widget.ctrl.patch(widget.account.id, {'isDefault': true}),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                // Fixed border width — avoids layout shift during animation
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Content row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bank icon — background and icon colour both lerp
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_rounded,
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name / holder / IBAN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.account.bankName.isNotEmpty
                                    ? widget.account.bankName
                                    : BusinessBankAccountScreenStrings
                                          .cardFallbackName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: nameColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget
                                  .account
                                  .accountHolderName
                                  .isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.account.accountHolderName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (widget.account.iban.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.credit_card_rounded,
                                      size: 13,
                                      color: AppColors.textHint,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _maskedIban(widget.account.iban),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                        fontFamily: 'monospace',
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Radio / spinner — swap with AnimatedSwitcher
                        const SizedBox(width: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: (saving && !widget.account.isDefault)
                              ? const SizedBox(
                                  key: ValueKey('spinner'),
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('radio'),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: radioFill,
                                    border: Border.all(
                                      color: radioBorder,
                                      width: 2,
                                    ),
                                  ),
                                  child: Opacity(
                                    opacity: v,
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Row(
                      children: [
                        if (widget.account.iban.isNotEmpty)
                          _CardAction(
                            icon: Icons.copy_rounded,
                            label:
                                BusinessBankAccountScreenStrings.cardCopyIban,
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.account.iban),
                              );
                              final msg = BusinessBankAccountScreenStrings
                                  .cardIbanCopied;
                              AppSnackbar.success(
                                '',
                                msg,
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                        const Spacer(),
                        _IconBtn(
                          icon: Icons.edit_outlined,
                          onTap: widget.onEdit,
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.error,
                          background: AppColors.errorLight,
                          onTap: saving ? null : () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _CardAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon-only action button
// ---------------------------------------------------------------------------

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color background;

  const _IconBtn({
    required this.icon,
    this.onTap,
    this.color = AppColors.textSecondary,
    this.background = AppColors.gray100,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 16,
          color: disabled ? AppColors.gray300 : color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / Edit bottom sheet
// ---------------------------------------------------------------------------

class _AccountSheet extends StatefulWidget {
  final BankAccountController ctrl;
  final BankAccountModel? existing;

  const _AccountSheet({required this.ctrl, this.existing});

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bankName;
  late final TextEditingController _holderName;
  late final TextEditingController _iban;
  late final TextEditingController _swift;
  late final TextEditingController _accountNr;
  bool _isDefault = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _bankName = TextEditingController(text: ex?.bankName ?? '');
    _holderName = TextEditingController(text: ex?.accountHolderName ?? '');
    _iban = TextEditingController(text: ex?.iban ?? '');
    _swift = TextEditingController(text: ex?.swiftOrBicCode ?? '');
    _accountNr = TextEditingController(text: ex?.accountNumber ?? '');
    _isDefault = ex?.isDefault ?? false;
  }

  @override
  void dispose() {
    _bankName.dispose();
    _holderName.dispose();
    _iban.dispose();
    _swift.dispose();
    _accountNr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    bool ok;
    if (_isEditing) {
      ok = await widget.ctrl.patch(widget.existing!.id, {
        'bankName': _bankName.text.trim(),
        'accountHolderName': _holderName.text.trim(),
        'iban': _iban.text.trim(),
        'swiftOrBicCode': _swift.text.trim(),
        'accountNumber': _accountNr.text.trim(),
        'isDefault': _isDefault,
      });
    } else {
      ok = await widget.ctrl.create(
        BankAccountModel(
          id: '',
          businessPartnerIri: '',
          bankName: _bankName.text.trim(),
          accountHolderName: _holderName.text.trim(),
          iban: _iban.text.trim(),
          swiftOrBicCode: _swift.text.trim(),
          accountNumber: _accountNr.text.trim(),
          isDefault: _isDefault,
        ),
      );
    }

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _isEditing
                      ? BusinessBankAccountScreenStrings.sheetTitleEdit
                      : BusinessBankAccountScreenStrings.sheetTitleAdd,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AppColors.divider),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormField(
                      controller: _bankName,
                      label: BusinessBankAccountScreenStrings.fieldBankName,
                      hint: BusinessBankAccountScreenStrings.fieldBankNameHint,
                      icon: Icons.account_balance_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? BusinessBankAccountScreenStrings.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _holderName,
                      label: BusinessBankAccountScreenStrings.fieldHolderName,
                      hint:
                          BusinessBankAccountScreenStrings.fieldHolderNameHint,
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? BusinessBankAccountScreenStrings.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _iban,
                      label: BusinessBankAccountScreenStrings.fieldIban,
                      hint: BusinessBankAccountScreenStrings.fieldIbanHint,
                      icon: Icons.credit_card_rounded,
                      keyboardType: TextInputType.text,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? BusinessBankAccountScreenStrings.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _swift,
                      label: BusinessBankAccountScreenStrings.fieldSwift,
                      hint: BusinessBankAccountScreenStrings.fieldSwiftHint,
                      icon: Icons.swap_horiz_rounded,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _accountNr,
                      label:
                          BusinessBankAccountScreenStrings.fieldAccountNumber,
                      hint: BusinessBankAccountScreenStrings
                          .fieldAccountNumberHint,
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Default toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_outline_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  BusinessBankAccountScreenStrings
                                      .defaultToggleLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  BusinessBankAccountScreenStrings
                                      .defaultToggleSubtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isDefault,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primaryLight,
                            onChanged: (v) => setState(() => _isDefault = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save button
                    Obx(() {
                      final saving = widget.ctrl.isSaving.value;
                      return CustomDynamicButton(
                        label: _isEditing
                            ? BusinessBankAccountScreenStrings.saveButton
                            : BusinessBankAccountScreenStrings.addButton,
                        onPressed: _save,
                        isLoading: saving,
                        accentColor: AppColors.primary,
                        fullWidth: true,
                        borderRadius: 14,
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form field row
// ---------------------------------------------------------------------------

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.field,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// White card wrapper
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// Cash payment toggle row
// ---------------------------------------------------------------------------

class _CashToggleRow extends StatelessWidget {
  final BusinessPartnerController ctrl;
  const _CashToggleRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOn = ctrl.partner.value?.acceptsCashPayment ?? false;
      final isUpdating = ctrl.isTogglingCash.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isOn ? AppColors.warningLight : AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.payments_outlined,
                size: 18,
                color: isOn ? AppColors.warningDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BusinessBankAccountScreenStrings.cashToggleLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isOn
                          ? BusinessBankAccountScreenStrings
                                .cashToggleOnSubtitle
                          : BusinessBankAccountScreenStrings
                                .cashToggleOffSubtitle,
                      key: ValueKey(isOn),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOn
                            ? AppColors.warningDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch.adaptive(
                    value: isOn,
                    activeThumbColor: AppColors.warningDark,
                    activeTrackColor: AppColors.warningLight,
                    onChanged: (v) => ctrl.setAcceptsCashPayment(v),
                  ),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Hint banner
// ---------------------------------------------------------------------------

class _HintBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HintBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
