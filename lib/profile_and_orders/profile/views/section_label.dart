// Uppercase section header used across settings, profile, about, and payment
// screens. Renders the label in small-caps gray style to visually separate
// content groups in a scrollable list.

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.gray400,
        ),
      ),
    );
  }
}
