import 'package:flutter/material.dart';
import 'package:food_app/strings/legal_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/legal_document_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScaffold(
      title: LegalStrings.privacyTitle,
      headerIcon: Icons.privacy_tip_outlined,
      gradientColors: const [AppColors.infoDark, AppColors.navy],
      subtitle: LegalStrings.privacySubtitle,
      lastUpdated: LegalStrings.privacyUpdated,
      highlights: [
        LegalHighlight(
          icon: Icons.lock_outline_rounded,
          color: AppColors.infoDark,
          label: LegalStrings.privacyH1,
        ),
        LegalHighlight(
          icon: Icons.visibility_off_outlined,
          color: AppColors.purple,
          label: LegalStrings.privacyH2,
        ),
        LegalHighlight(
          icon: Icons.verified_user_outlined,
          color: AppColors.success,
          label: LegalStrings.privacyH3,
        ),
        LegalHighlight(
          icon: Icons.delete_outline_rounded,
          color: AppColors.error,
          label: LegalStrings.privacyH4,
        ),
      ],
      sections: [
        LegalSection(
          title: LegalStrings.privacyS1T,
          body: LegalStrings.privacyS1B,
        ),
        LegalSection(
          title: LegalStrings.privacyS2T,
          body: LegalStrings.privacyS2B,
        ),
        LegalSection(
          title: LegalStrings.privacyS3T,
          body: LegalStrings.privacyS3B,
        ),
        LegalSection(
          title: LegalStrings.privacyS4T,
          body: LegalStrings.privacyS4B,
        ),
        LegalSection(
          title: LegalStrings.privacyS5T,
          body: LegalStrings.privacyS5B,
        ),
        LegalSection(
          title: LegalStrings.privacyS6T,
          body: LegalStrings.privacyS6B,
        ),
        LegalSection(
          title: LegalStrings.privacyS7T,
          body: LegalStrings.privacyS7B,
        ),
        LegalSection(
          title: LegalStrings.privacyS8T,
          body: LegalStrings.privacyS8B,
        ),
      ],
    );
  }
}
