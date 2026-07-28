import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'customer_profile_strings.dart';
import 'support_hero_header.dart';
import 'support_scaffold.dart';
import 'package:get/get.dart';

class ContactEmailScreen extends StatefulWidget {
  const ContactEmailScreen({super.key});

  @override
  State<ContactEmailScreen> createState() => _ContactEmailScreenState();
}

class _ContactEmailScreenState extends State<ContactEmailScreen> {
  final TextEditingController _message = TextEditingController();
  int _selectedSubject = 0;
  bool _sending = false;

  List<({String label, IconData icon})> get _subjects => [
    (
      label: CustomerProfileStrings.emailSubjectOrder,
      icon: Icons.receipt_long_outlined,
    ),
    (
      label: CustomerProfileStrings.emailSubjectDelivery,
      icon: Icons.delivery_dining_outlined,
    ),
    (
      label: CustomerProfileStrings.emailSubjectPayment,
      icon: Icons.credit_card_outlined,
    ),
    (
      label: CustomerProfileStrings.emailSubjectGeneral,
      icon: Icons.help_outline_rounded,
    ),
  ];

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) {
      AppSnackbar.success(
        CustomerProfileStrings.emailRequired,
        CustomerProfileStrings.emailRequiredSub,
      );
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _sending = false);
    Get.back();
    AppSnackbar.success(
      CustomerProfileStrings.emailSentTitle,
      CustomerProfileStrings.emailSentSub,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Left/right insets from the device notch/cutout in landscape
    final safe = MediaQuery.of(context).padding;
    // Horizontal content padding that respects the safe area
    final hPad = safe.left + 16.0;
    final hPadRight = safe.right + 16.0;

    return SupportScaffold(
      appBarColor: AppColors.infoDark,
      titleWidget: Text(
        CustomerProfileStrings.emailSupportTitle,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          // Header handles its own safe-area padding; ListView bottom
          // uses the device's bottom inset so content clears the home bar.
          padding: EdgeInsets.only(bottom: safe.bottom + 32),
          children: [
            SupportHeroHeader(
              icon: Icons.email_outlined,
              gradientColors: const [AppColors.info, AppColors.infoDark],
              title: CustomerProfileStrings.emailSupportTitle,
              subtitle: CustomerProfileStrings.emailSupportSubtitle,
              badge: CustomerProfileStrings.emailBadge,
              badgeColor: AppColors.info,
            ),

            const SizedBox(height: 20),

            if (isLandscape)
              // ── Landscape: two-column form ─────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: info + subject
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.schedule_rounded,
                            iconColor: AppColors.info,
                            label: CustomerProfileStrings.emailResponseShort,
                            value: CustomerProfileStrings.emailResponseValue,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            CustomerProfileStrings.emailSubjectLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SubjectGrid(
                            subjects: _subjects,
                            selected: _selectedSubject,
                            onSelect: (i) =>
                                setState(() => _selectedSubject = i),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Right: message + send
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CustomerProfileStrings.emailMessageLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _MessageField(controller: _message),
                          const SizedBox(height: 12),
                          _SendButton(sending: _sending, onSend: _send),
                          const SizedBox(height: 8),
                          _PrivacyNote(),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // ── Portrait: stacked form ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
                child: _InfoRow(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.info,
                  label: CustomerProfileStrings.emailResponseLabel,
                  value: CustomerProfileStrings.emailResponseValue,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
                child: Text(
                  CustomerProfileStrings.emailSubjectLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _subjects.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _SubjectChip(
                    subject: _subjects[i],
                    selected: i == _selectedSubject,
                    onTap: () => setState(() => _selectedSubject = i),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CustomerProfileStrings.emailMessageLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MessageField(controller: _message),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
                child: _SendButton(sending: _sending, onSend: _send),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPadRight, 0),
                child: _PrivacyNote(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Subject chips — wrapping grid for landscape ───────────────────────────────

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({
    required this.subjects,
    required this.selected,
    required this.onSelect,
  });

  final List<({String label, IconData icon})> subjects;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects.asMap().entries.map((e) {
        return _SubjectChip(
          subject: e.value,
          selected: e.key == selected,
          onTap: () => onSelect(e.key),
        );
      }).toList(),
    );
  }
}

// ── Single subject chip ───────────────────────────────────────────────────────

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final ({String label, IconData icon}) subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.info : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.info : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              subject.icon,
              size: 14,
              color: selected ? AppColors.white : AppColors.gray500,
            ),
            const SizedBox(width: 6),
            Text(
              subject.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message text field ────────────────────────────────────────────────────────

class _MessageField extends StatelessWidget {
  const _MessageField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: 7,
        minLines: 4,
        style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5),
        decoration: InputDecoration(
          hintText: CustomerProfileStrings.emailMessageHint,
          hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onSend});
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return CustomDynamicButton(
      fullWidth: true,
      borderRadius: 14,
      accentColor: AppColors.info,
      isLoading: sending,
      icon: Icons.send_rounded,
      label: CustomerProfileStrings.emailSendBtn,
      onPressed: onSend,
    );
  }
}

// ── Privacy note ──────────────────────────────────────────────────────────────

class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: AppColors.gray400,
        ),
        const SizedBox(width: 6),
        Text(
          CustomerProfileStrings.emailPrivacy,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
