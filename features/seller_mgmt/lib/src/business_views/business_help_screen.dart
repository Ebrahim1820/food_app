import 'package:flutter/material.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class BusinessHelpScreen extends StatelessWidget {
  const BusinessHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          BusinessHelpStrings.appBarTitle,
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
            // ── Quick contact options ────────────────────────────────────────
            Text(
              BusinessHelpStrings.getInTouch,
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
                    label: BusinessHelpStrings.liveChat,
                    sublabel: BusinessHelpStrings.liveChatSub,
                    onTap: () => AppSnackbar.success(
                      BusinessHelpStrings.liveChat,
                      BusinessHelpStrings.snackChat,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.email_outlined,
                    color: AppColors.infoDark,
                    label: BusinessHelpStrings.email,
                    sublabel: BusinessHelpStrings.emailSub,
                    onTap: () => AppSnackbar.success(
                      BusinessHelpStrings.email,
                      BusinessHelpStrings.snackEmail,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.phone_outlined,
                    color: AppColors.warningDark,
                    label: BusinessHelpStrings.call,
                    sublabel: BusinessHelpStrings.callSub,
                    onTap: () => AppSnackbar.success(
                      BusinessHelpStrings.call,
                      BusinessHelpStrings.snackCall,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── FAQ ──────────────────────────────────────────────────────────
            Text(
              BusinessHelpStrings.faqTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
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
                child: Builder(
                  builder: (context) {
                    final faqs = BusinessHelpStrings.faqs;
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

            const SizedBox(height: 24),

            // ── Documentation link ───────────────────────────────────────────
            _DocBanner(),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

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

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.showDivider,
  });

  final String question;
  final String answer;
  final bool showDivider;

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

class _DocBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppSnackbar.success(
        BusinessHelpStrings.visitCentre,
        BusinessHelpStrings.snackCentre,
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
                    BusinessHelpStrings.visitCentre,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    BusinessHelpStrings.centreSub,
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
