import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_app/controllers/locale_controller.dart';
import 'package:food_app/theme/app_colors.dart';

/// A compact flag-pill that sits in any AppBar's [actions].
/// One tap toggles between English 🇬🇧 and Farsi 🇮🇷.
/// Always renders LTR so the pill reads left-to-right regardless of locale.
///
/// Use [onDark] when placing on a dark or coloured background (e.g. the green
/// customer header) — swaps the pill to a semi-transparent white style.
class LanguageFlagSwitcher extends StatelessWidget {
  final bool onDark;

  const LanguageFlagSwitcher({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<LocaleController>();

    return Obx(() {
      final isEn = ctrl.isEnglish;
      final flag = isEn ? '🇬🇧' : '🇮🇷';
      final code = isEn ? 'EN' : 'FA';

      final pillColor = onDark
          ? Colors.white.withValues(alpha: 0.18)
          : AppColors.gray100;
      final borderColor = onDark
          ? Colors.white.withValues(alpha: 0.35)
          : AppColors.border;
      final textColor = onDark ? AppColors.white : AppColors.navy;

      return Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: InkWell(
            onTap: isEn ? ctrl.switchToFarsi : ctrl.switchToEnglish,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 16, height: 1.2)),
                  const SizedBox(width: 5),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
