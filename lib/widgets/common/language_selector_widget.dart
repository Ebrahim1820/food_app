import 'package:flutter/material.dart';
import 'package:i18n/i18n.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Two-button EN / FA language selector used on settings screens.
///
/// Always rendered LTR so the button order (English left, Farsi right) and
/// the card's corner radii stay correct regardless of the active locale.
class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleController>();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
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
        child: Obx(() {
          final isEn = locale.isEnglish;
          return Row(
            children: [
              Expanded(
                child: _LangButton(
                  label: CustomerProfileStrings.languageEnglish,
                  flag: '🇬🇧',
                  selected: isEn,
                  onTap: locale.switchToEnglish,
                  isFirst: true,
                ),
              ),
              Expanded(
                child: _LangButton(
                  label: CustomerProfileStrings.languageFarsi,
                  flag: '🇮🇷',
                  selected: !isEn,
                  onTap: locale.switchToFarsi,
                  isFirst: false,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
    required this.isFirst,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  /// True = English (always visually left). False = Farsi (always visually right).
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(14) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(14) : Radius.zero,
            topRight: isFirst ? Radius.zero : const Radius.circular(14),
            bottomRight: isFirst ? Radius.zero : const Radius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
