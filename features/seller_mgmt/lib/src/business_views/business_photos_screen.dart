import 'package:flutter/material.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Photos & Branding Screen
//
// Allows the business owner to manage three image types:
//   1. Logo         – the small brand icon shown in the app bar / search results
//   2. Cover Photo  – the wide hero banner on the business detail page
//   3. Gallery      – up to 6 additional photos of dishes, interior, etc.
//
// Logo upload is handled by UploadableAvatar (reuses the same widget we use
// everywhere else). Cover and gallery are placeholders for now.
// ---------------------------------------------------------------------------

class BusinessPhotosScreen extends StatelessWidget {
  const BusinessPhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bpCtrl = Get.find<BusinessPartnerController>();
    final partner = bpCtrl.partner.value;

    // Short label to use as initials when no logo is uploaded yet
    final initials = (partner?.businessName.isNotEmpty == true)
        ? partner!.businessName.characters.first.toUpperCase()
        : '?';

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
          BusinessPhotosStrings.appBarTitle,
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
            // ── Logo section ──────────────────────────────────────────────────
            // The logo appears everywhere customers see the brand: search results,
            // the dashboard app bar, order receipts, etc.
            _SectionHeader(
              icon: Icons.storefront_outlined,
              iconColor: AppColors.primary,
              title: BusinessPhotosStrings.logoTitle,
              subtitle: BusinessPhotosStrings.logoSubtitle,
            ),
            const SizedBox(height: 16),
            Center(
              child: Obx(() {
                // Re-read partner inside Obx so the logo refreshes after upload
                final p = bpCtrl.partner.value;
                final ini = (p?.businessName.isNotEmpty == true)
                    ? p!.businessName.characters.first.toUpperCase()
                    : initials;
                return Column(
                  children: [
                    // Reuse UploadableAvatar so the logo upload logic is shared
                    UploadableAvatar(
                      initials: ini,
                      imageType: 'business_logo',
                      partnerIri: p?.iri,
                      size: 100,
                      borderRadius: 24,
                      backgroundColor: AppColors.primaryLight,
                      initialsColor: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      BusinessPhotosStrings.tapToChangeLogo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 28),

            // ── Cover Photo section ───────────────────────────────────────────
            // The cover is the large banner customers see when they open the
            // business page. Ideal size: 1200 × 400 px (3:1 ratio).
            _SectionHeader(
              icon: Icons.image_outlined,
              iconColor: AppColors.purple,
              title: BusinessPhotosStrings.coverTitle,
              subtitle: BusinessPhotosStrings.coverSubtitle,
            ),
            const SizedBox(height: 16),
            _CoverPhotoPlaceholder(),

            const SizedBox(height: 28),

            // ── Gallery section ───────────────────────────────────────────────
            // Up to 6 photos showing your food, ambiance, or team.
            _SectionHeader(
              icon: Icons.collections_outlined,
              iconColor: AppColors.accent,
              title: BusinessPhotosStrings.galleryTitle,
              subtitle: BusinessPhotosStrings.gallerySubtitle,
            ),
            const SizedBox(height: 16),
            _GalleryGrid(),

            const SizedBox(height: 12),
            // Tip card at the bottom
            _TipCard(text: BusinessPhotosStrings.tipText),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header with coloured icon badge + title/subtitle
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wide dashed-border placeholder for the cover photo
// ---------------------------------------------------------------------------
class _CoverPhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppSnackbar.success(
        BusinessPhotosStrings.comingSoonSnack,
        BusinessPhotosStrings.comingSoonBody,
      ),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.purpleLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: AppColors.purple,
              ),
              const SizedBox(height: 8),
              Text(
                BusinessPhotosStrings.uploadCoverButton,
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                BusinessPhotosStrings.coverRecommendedSize,
                style: const TextStyle(color: AppColors.purple, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3-column grid of gallery photo slots (max 6)
// ---------------------------------------------------------------------------
class _GalleryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => _GallerySlot(index: i),
    );
  }
}

// A single gallery slot — shows a photo if uploaded, or an "add" placeholder
class _GallerySlot extends StatelessWidget {
  const _GallerySlot({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppSnackbar.success(
        BusinessPhotosStrings.comingSoonSnack,
        BusinessPhotosStrings.comingSoonBody,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.accent, size: 24),
            const SizedBox(height: 4),
            Text(
              BusinessPhotosStrings.photoSlot(index + 1),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.accentDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A green tip card shown at the bottom of the screen
// ---------------------------------------------------------------------------
class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.successDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.successDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
