// Customer — Help & Support Screen
//
// Three sections:
//   1. Quick contact options (Live Chat, Email, Call Us) — tappable cards
//   2. FAQ — expandable tiles with the most common customer questions
//   3. A banner linking to the full online Help Centre

import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/profile/views/call_us_screen.dart';
import 'package:food_app/profile_and_orders/profile/views/contact_email_screen.dart';
import 'package:food_app/profile_and_orders/profile/views/live_chat_screen.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

class CustomerHelpScreen extends StatelessWidget {
  const CustomerHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          CustomerProfileStrings.helpTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // ── Contact cards ────────────────────────────────────────────────
            Text(
              CustomerProfileStrings.helpGetInTouch,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    label: CustomerProfileStrings.helpLiveChat,
                    sublabel: CustomerProfileStrings.helpChatSub,
                    onTap: () => Get.to(() => const LiveChatScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.email_outlined,
                    color: AppColors.infoDark,
                    label: CustomerProfileStrings.helpEmail,
                    sublabel: CustomerProfileStrings.helpEmailSub,
                    onTap: () => Get.to(() => const ContactEmailScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.phone_outlined,
                    color: AppColors.warningDark,
                    label: CustomerProfileStrings.helpCall,
                    sublabel: CustomerProfileStrings.helpCallSub,
                    onTap: () => Get.to(() => const CallUsScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Opening hours info card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    CustomerProfileStrings.helpOpening,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CustomerProfileStrings.helpOpeningValue,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── FAQ ──────────────────────────────────────────────────────────
            Text(
              CustomerProfileStrings.helpFaq,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            // Shadow lives in the outer Container; Material provides the ink
            // surface that ExpansionTile's internal ListTile requires.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Material(
                  color: AppColors.white,
                  child: Builder(
                    builder: (context) {
                      final faqs = CustomerProfileStrings.helpFaqs;
                      return Column(
                        children: faqs
                            .asMap()
                            .entries
                            .map(
                              (e) => _FaqTile(
                                question: e.value.q,
                                answer: e.value.a,
                                showDivider: e.key < faqs.length - 1,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Help Centre banner ────────────────────────────────────────────
            _HelpCentreBanner(),
          ],
        ),
      ),
    );
  }
}

// ── Contact channel card ──────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expandable FAQ row ────────────────────────────────────────────────────────

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool showDivider;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.gray400,
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, color: AppColors.divider),
      ],
    );
  }
}

// ── Help Centre banner ────────────────────────────────────────────────────────

class _HelpCentreBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppSnackbar.success(
        CustomerProfileStrings.helpVisitCentre,
        CustomerProfileStrings.helpSnackCentre,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              color: AppColors.white,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CustomerProfileStrings.helpVisitCentre,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CustomerProfileStrings.helpCentreSub,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
