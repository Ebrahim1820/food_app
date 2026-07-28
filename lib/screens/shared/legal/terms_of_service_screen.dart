import 'package:flutter/material.dart';
import 'package:i18n/i18n.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/legal_document_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScaffold(
      title: LegalStrings.termsTitle,
      headerIcon: Icons.description_outlined,
      gradientColors: const [AppColors.gray700, AppColors.gray900],
      subtitle: LegalStrings.termsSubtitle,
      lastUpdated: LegalStrings.termsUpdated,
      highlights: [
        LegalHighlight(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          label: LegalStrings.termsH1,
        ),
        LegalHighlight(
          icon: Icons.gavel_rounded,
          color: AppColors.warningDark,
          label: LegalStrings.termsH2,
        ),
        LegalHighlight(
          icon: Icons.local_shipping_outlined,
          color: AppColors.primary,
          label: LegalStrings.termsH3,
        ),
        LegalHighlight(
          icon: Icons.block_rounded,
          color: AppColors.error,
          label: LegalStrings.termsH4,
        ),
      ],
      sections: [
        LegalSection(title: LegalStrings.termsS1T, body: LegalStrings.termsS1B),
        LegalSection(title: LegalStrings.termsS2T, body: LegalStrings.termsS2B),
        LegalSection(title: LegalStrings.termsS3T, body: LegalStrings.termsS3B),
        LegalSection(title: LegalStrings.termsS4T, body: LegalStrings.termsS4B),
        LegalSection(title: LegalStrings.termsS5T, body: LegalStrings.termsS5B),
        LegalSection(title: LegalStrings.termsS6T, body: LegalStrings.termsS6B),
        LegalSection(title: LegalStrings.termsS7T, body: LegalStrings.termsS7B),
        LegalSection(title: LegalStrings.termsS8T, body: LegalStrings.termsS8B),
      ],
    );
  }
}
