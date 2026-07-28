import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/profile_and_orders/profile/views/support_hero_header.dart';
import 'package:food_app/profile_and_orders/profile/views/support_scaffold.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';

class CallUsScreen extends StatelessWidget {
  const CallUsScreen({super.key});

  static const _phone = '+1 (800) 123-4567';
  static const _whatsapp = '+1 (800) 765-4321';

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final safe = MediaQuery.of(context).padding;
    final hPad = safe.left + 16.0;
    final hPadRight = safe.right + 16.0;

    return SupportScaffold(
      appBarColor: AppColors.warningDark,
      titleWidget: Text(
        CustomerProfileStrings.helpCall,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: safe.bottom + 24),
        children: [
          SupportHeroHeader(
            icon: Icons.phone_outlined,
            gradientColors: const [AppColors.warning, AppColors.warningDark],
            title: CustomerProfileStrings.callSupportTitle,
            subtitle: CustomerProfileStrings.callSupportSubtitle,
            badge: CustomerProfileStrings.callBadge,
            badgeColor: AppColors.success,
          ),

          const SizedBox(height: 16),

          if (isLandscape)
            // ── Landscape: phone card left, details right ──────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _CompactPhoneCard(phone: _phone)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        _SectionCard(
                          title: CustomerProfileStrings.callAvailability,
                          icon: Icons.schedule_rounded,
                          iconColor: AppColors.primary,
                          children: [
                            _AvailabilityRow(
                              day: CustomerProfileStrings.callMonFriShort,
                              hours: CustomerProfileStrings.callMonFriHours,
                            ),
                            _AvailabilityRow(
                              day: CustomerProfileStrings.callSat,
                              hours: CustomerProfileStrings.callSatHours,
                            ),
                            _AvailabilityRow(
                              day: CustomerProfileStrings.callSun,
                              hours: CustomerProfileStrings.callSunHours,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SectionCard(
                          title: CustomerProfileStrings.callAlternative,
                          icon: Icons.contacts_outlined,
                          iconColor: AppColors.purple,
                          children: [
                            _AlternativeContactTile(
                              icon: Icons.whatshot_rounded,
                              iconColor: const Color(0xFF25D366),
                              bgColor: const Color(0xFFDCFCE7),
                              label: CustomerProfileStrings.callWhatsapp,
                              value: _whatsapp,
                              onTap: () => AppSnackbar.success(
                                CustomerProfileStrings.callOpeningWhatsapp,
                                '${CustomerProfileStrings.callOpeningWhatsapp} $_whatsapp',
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 14,
                              color: AppColors.divider,
                            ),
                            _AlternativeContactTile(
                              icon: Icons.sms_outlined,
                              iconColor: AppColors.info,
                              bgColor: AppColors.infoLight,
                              label: CustomerProfileStrings.callSms,
                              value: _phone,
                              onTap: () => AppSnackbar.success(
                                CustomerProfileStrings.callOpeningSms,
                                '${CustomerProfileStrings.callOpeningSms} $_phone',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // ── Portrait: stacked layout ───────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
              child: _FullPhoneCard(phone: _phone),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
              child: _SectionCard(
                title: CustomerProfileStrings.callAvailability,
                icon: Icons.schedule_rounded,
                iconColor: AppColors.primary,
                children: [
                  _AvailabilityRow(
                    day: CustomerProfileStrings.callMonFri,
                    hours: CustomerProfileStrings.callMonFriHours,
                  ),
                  _AvailabilityRow(
                    day: CustomerProfileStrings.callSat,
                    hours: CustomerProfileStrings.callSatHours,
                  ),
                  _AvailabilityRow(
                    day: CustomerProfileStrings.callSun,
                    hours: CustomerProfileStrings.callSunHours,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
              child: _SectionCard(
                title: CustomerProfileStrings.callAlternative,
                icon: Icons.contacts_outlined,
                iconColor: AppColors.purple,
                children: [
                  _AlternativeContactTile(
                    icon: Icons.whatshot_rounded,
                    iconColor: const Color(0xFF25D366),
                    bgColor: const Color(0xFFDCFCE7),
                    label: CustomerProfileStrings.callWhatsapp,
                    value: _whatsapp,
                    onTap: () => AppSnackbar.success(
                      CustomerProfileStrings.callOpeningWhatsapp,
                      '${CustomerProfileStrings.callOpeningWhatsapp} $_whatsapp',
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: 14,
                    color: AppColors.divider,
                  ),
                  _AlternativeContactTile(
                    icon: Icons.sms_outlined,
                    iconColor: AppColors.info,
                    bgColor: AppColors.infoLight,
                    label: CustomerProfileStrings.callSms,
                    value: _phone,
                    onTap: () => AppSnackbar.success(
                      CustomerProfileStrings.callOpeningSms,
                      '${CustomerProfileStrings.callOpeningSms} $_phone',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Full phone card (portrait) ────────────────────────────────────────────────

class _FullPhoneCard extends StatelessWidget {
  const _FullPhoneCard({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    return _PhoneCardBase(
      phone: phone,
      iconSize: 28,
      numberFontSize: 22,
      topPadding: 20,
      bottomPadding: 20,
    );
  }
}

// ── Compact phone card (landscape) ───────────────────────────────────────────

class _CompactPhoneCard extends StatelessWidget {
  const _CompactPhoneCard({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    return _PhoneCardBase(
      phone: phone,
      iconSize: 22,
      numberFontSize: 18,
      topPadding: 14,
      bottomPadding: 14,
    );
  }
}

// ── Shared phone card base ────────────────────────────────────────────────────

class _PhoneCardBase extends StatelessWidget {
  const _PhoneCardBase({
    required this.phone,
    required this.iconSize,
    required this.numberFontSize,
    required this.topPadding,
    required this.bottomPadding,
  });

  final String phone;
  final double iconSize;
  final double numberFontSize;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, topPadding, 18, bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(iconSize * 0.5),
            decoration: const BoxDecoration(
              color: AppColors.warningLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_in_talk_rounded,
              color: AppColors.warningDark,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            CustomerProfileStrings.callHotlineLabel,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: phone));
              AppSnackbar.success(
                CustomerProfileStrings.callCopied,
                CustomerProfileStrings.callCopiedSub,
                duration: const Duration(seconds: 2),
              );
            },
            child: Text(
              phone,
              style: TextStyle(
                fontSize: numberFontSize,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CustomerProfileStrings.callHoldCopy,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          CustomDynamicButton(
            fullWidth: true,
            borderRadius: 12,
            accentColor: AppColors.warningDark,
            icon: Icons.phone_rounded,
            label: CustomerProfileStrings.callNowBtn,
            onPressed: () => AppSnackbar.success(
              CustomerProfileStrings.callDialing,
              '${CustomerProfileStrings.callDialing} $phone',
              duration: const Duration(seconds: 3),
            ),
          ),
          const SizedBox(height: 8),
          CustomDynamicButton(
            variant: CustomButtonVariant.outlined,
            fullWidth: true,
            borderRadius: 12,
            accentColor: AppColors.warningDark,
            icon: Icons.phone_callback_rounded,
            label: CustomerProfileStrings.callbackBtn,
            onPressed: () => AppSnackbar.success(
              CustomerProfileStrings.callbackRequested,
              CustomerProfileStrings.callbackSub,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

// ── Availability row ──────────────────────────────────────────────────────────

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.day, required this.hours});
  final String day;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            hours,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alternative contact tile ──────────────────────────────────────────────────

class _AlternativeContactTile extends StatelessWidget {
  const _AlternativeContactTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
