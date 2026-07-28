import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/models/business_partner_model.dart';
import 'package:food_app/models/address_model.dart';
import 'package:food_app/screens/food_teil/business_views/business_reviews_screen.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:food_app/widgets/uploadable_avatar.dart';
import 'package:get/get.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BusinessPartnerController>();

    if (ctrl.partner.value == null && !ctrl.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ctrl.fetchMyPartner(),
      );
    }

    return Obx(() {
      final partner = ctrl.partner.value;

      if (ctrl.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (partner == null) {
        return Scaffold(
          appBar: AppBar(title: Text(BusinessProfileStrings.appBarTitle)),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.store_outlined,
                  size: 48,
                  color: AppColors.gray300,
                ),
                const SizedBox(height: 12),
                Text(
                  ctrl.fetchError.value ?? BusinessProfileStrings.couldNotLoad,
                  style: const TextStyle(color: AppColors.gray500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomDynamicButton(
                  label: BusinessProfileStrings.retry,
                  onPressed: ctrl.fetchMyPartner,
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              _ProfileHeader(partner: partner),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    children: [
                      _StatsRow(partner: partner),
                      const SizedBox(height: 20),
                      _InfoSection(
                        icon: Icons.storefront_outlined,
                        title: BusinessProfileStrings.sectionBusinessDetails,
                        items: [
                          _InfoItem(
                            BusinessProfileStrings.labelBusinessName,
                            partner.businessName,
                            Icons.badge_outlined,
                          ),
                          _InfoItem(
                            BusinessProfileStrings.labelOwner,
                            partner.ownerName,
                            Icons.person_outline,
                          ),
                          _InfoItem(
                            BusinessProfileStrings.labelRegistrationNumber,
                            partner.registrationBusinessNumber.isEmpty
                                ? '—'
                                : partner.registrationBusinessNumber,
                            Icons.article_outlined,
                          ),
                          _InfoItem(
                            BusinessProfileStrings.labelKycStatus,
                            partner.kycStatus,
                            Icons.verified_outlined,
                            valueColor: _kycColor(partner.kycStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (partner.addresses.isNotEmpty) ...[
                        _LocationSection(addresses: partner.addresses),
                        const SizedBox(height: 16),
                      ],
                      _InfoSection(
                        icon: Icons.receipt_long_outlined,
                        title: BusinessProfileStrings.sectionTaxInfo,
                        items: [
                          _InfoItem(
                            BusinessProfileStrings.labelTaxNumber,
                            partner.taxNumber.isEmpty ? '—' : partner.taxNumber,
                            Icons.numbers_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PaymentSettingsSection(ctrl: ctrl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _kycColor(String status) {
    return switch (status.toLowerCase()) {
      'approved' => AppColors.successDark,
      'pending' => AppColors.warningDark,
      'rejected' => AppColors.error,
      _ => AppColors.gray500,
    };
  }
}

// ---------------------------------------------------------------------------
// Sliver hero header
// ---------------------------------------------------------------------------
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.partner});
  final BusinessPartnerModel partner;

  @override
  Widget build(BuildContext context) {
    final initials = partner.businessName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return SliverAppBar(
      expandedHeight: (MediaQuery.of(context).size.height * 0.30).clamp(
        180.0,
        240.0,
      ),
      pinned: true,
      backgroundColor: AppColors.navy,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppColors.white,
        ),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F6E56), AppColors.navy],
                ),
              ),
            ),
            Opacity(
              opacity: 0.06,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (_, i) =>
                    const Icon(Icons.circle, size: 4, color: AppColors.white),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  UploadableAvatar(
                    initials: initials,
                    imageType: 'business_logo',
                    partnerIri: partner.iri,
                    size: 88,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    partner.businessName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _KycBadge(status: partner.kycStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final String status;
  const _KycBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'approved' => AppColors.successDark,
      'pending' => AppColors.warningDark,
      'rejected' => AppColors.error,
      _ => AppColors.gray400,
    };
    final bg = switch (status.toLowerCase()) {
      'approved' => AppColors.successLight,
      'pending' => AppColors.warningLight,
      'rejected' => AppColors.errorLight,
      _ => AppColors.gray100,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final BusinessPartnerModel partner;
  const _StatsRow({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      child: Row(
        children: [
          _StatItem(
            icon: Icons.star_rounded,
            color: AppColors.warning,
            value: CurrencyFormatter.localizeDigits(
              partner.rating.toStringAsFixed(1),
            ),
            label: BusinessProfileStrings.statRating,
            onTap: () =>
                Get.to(() => const BusinessReviewsScreen(standalone: true)),
          ),
          const _StatDivider(),
          _StatItem(
            icon: Icons.local_shipping_outlined,
            color: AppColors.info,
            value: CurrencyFormatter.format(
              double.tryParse(partner.deliveryFee) ?? 0,
            ),
            label: BusinessProfileStrings.statDelivery,
          ),
          const _StatDivider(),
          _StatItem(
            icon: partner.isActive ? Icons.circle : Icons.circle_outlined,
            color: partner.isActive ? AppColors.successDark : AppColors.gray400,
            value: partner.isActive
                ? BusinessProfileStrings.statusOpen
                : BusinessProfileStrings.statusClosed,
            label: BusinessProfileStrings.statStatus,
          ),
          const _StatDivider(),
          _StatItem(
            icon: partner.acceptsCashPayment
                ? Icons.payments_rounded
                : Icons.credit_card_rounded,
            color: partner.acceptsCashPayment
                ? AppColors.warningDark
                : AppColors.gray400,
            value: partner.acceptsCashPayment
                ? BusinessProfileStrings.cashYes
                : BusinessProfileStrings.cashNo,
            label: BusinessProfileStrings.statCash,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  /// Optional tap handler — when set, the whole stat becomes tappable
  /// (e.g. the rating stat opens the reviews screen).
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: content,
            ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }
}

// ---------------------------------------------------------------------------
// Info section card
// ---------------------------------------------------------------------------

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoItem> items;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.items,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...items.map((item) => item),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoItem(this.label, this.value, this.icon, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location section
// ---------------------------------------------------------------------------

class _LocationSection extends StatelessWidget {
  final List<AddressModel> addresses;
  const _LocationSection({required this.addresses});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  BusinessProfileStrings.sectionLocations,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...addresses.asMap().entries.map(
            (e) => _AddressCard(address: e.value, isPrimary: e.key == 0),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.isPrimary});
  final AddressModel address;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary : AppColors.gray300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPrimary)
                  Text(
                    BusinessProfileStrings.primaryBadge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                Text(
                  address.street,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${address.city}, ${address.postalCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  address.country,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment Settings Section
// ---------------------------------------------------------------------------

class _PaymentSettingsSection extends StatelessWidget {
  final BusinessPartnerController ctrl;

  const _PaymentSettingsSection({required this.ctrl});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.warningDark,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  BusinessProfileStrings.sectionPayment,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Cash toggle row
          Obx(() {
            final partner = ctrl.partner.value;
            final isOn = partner?.acceptsCashPayment ?? false;
            final isUpdating = ctrl.isTogglingCash.value;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isOn ? AppColors.warningLight : AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.money_rounded,
                      size: 20,
                      color: isOn
                          ? AppColors.warningDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BusinessProfileStrings.cashToggleTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOn
                              ? BusinessProfileStrings.cashToggleOnSub
                              : BusinessProfileStrings.cashToggleOffSub,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
          }),

          // Info hint
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    BusinessProfileStrings.cashHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _DeliveryFeeRow(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery fee — plain text/number field, PATCHed on save. Per-business (not
// per-offer): one fee covers every delivery order from this shop.
// ---------------------------------------------------------------------------

class _DeliveryFeeRow extends StatefulWidget {
  const _DeliveryFeeRow({required this.ctrl});
  final BusinessPartnerController ctrl;

  @override
  State<_DeliveryFeeRow> createState() => _DeliveryFeeRowState();
}

class _DeliveryFeeRowState extends State<_DeliveryFeeRow> {
  // Same money-input formatter used everywhere else in the app (see
  // business_offer_edit_screen.dart's _moneyFmt) — allows a comma decimal
  // separator and Persian digits, not just ASCII digits and a period.
  static final _moneyFmt = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.,۰-۹]'),
  );

  late final TextEditingController _textCtrl = TextEditingController(
    text: CurrencyFormatter.localizeDigits(
      widget.ctrl.partner.value?.deliveryFee ?? '0.00',
    ),
  );
  String? _errorText;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final typed = CurrencyFormatter.parseLocalizedDouble(_textCtrl.text);
    final current =
        double.tryParse(widget.ctrl.partner.value?.deliveryFee ?? '') ?? 0;
    return typed != current;
  }

  Future<void> _save() async {
    if (_textCtrl.text.trim().isEmpty) {
      setState(() => _errorText = BusinessProfileStrings.deliveryFeeInvalid);
      return;
    }
    // parseLocalizedDouble normalizes a comma decimal separator and Persian
    // digits (e.g. "۱٫۴۰" or "1,40") to a plain double — same helper every
    // other price field in the app uses, so behavior stays consistent.
    final value = CurrencyFormatter.parseLocalizedDouble(_textCtrl.text);
    if (value < 0) {
      setState(() => _errorText = BusinessProfileStrings.deliveryFeeInvalid);
      return;
    }
    setState(() => _errorText = null);

    final formatted = value.toStringAsFixed(2);
    final ok = await widget.ctrl.setDeliveryFee(formatted);
    if (!mounted) return;

    if (ok) {
      setState(() => _textCtrl.text = formatted);
      AppSnackbar.success(
        BusinessProfileStrings.sectionPayment,
        BusinessProfileStrings.deliveryFeeSavedSnack,
      );
    } else {
      AppSnackbar.error(
        BusinessProfileStrings.sectionPayment,
        widget.ctrl.fetchError.value ?? BusinessProfileStrings.couldNotLoad,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSaving = widget.ctrl.isSavingDeliveryFee.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppColors.infoDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BusinessProfileStrings.deliveryFeeTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    BusinessProfileStrings.deliveryFeeSub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _textCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [_moneyFmt],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixText: '€ ',
                            hintText: BusinessProfileStrings.deliveryFeeHint,
                            errorText: _errorText,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isSaving || _isDirty)
                        CustomDynamicButton(
                          label: BusinessProfileStrings.deliveryFeeSaveButton,
                          onPressed: _save,
                          isLoading: isSaving,
                          variant: CustomButtonVariant.text,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
