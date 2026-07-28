import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_app/services/app_storage.dart';
import 'package:food_app/theme/app_theme.dart';

class LocaleController extends GetxController {
  static const _storageKey = 'locale_lang';

  final locale = const Locale('en', 'US').obs;

  @override
  void onInit() {
    super.onInit();
    final saved = AppStorage.read<String>(_storageKey);
    if (saved == 'fa') {
      locale.value = const Locale('fa', 'IR');
    }
  }

  bool get isEnglish => locale.value.languageCode == 'en';
  bool get isFarsi => locale.value.languageCode == 'fa';

  void switchTo(Locale newLocale) {
    if (locale.value == newLocale) return;
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    Get.changeTheme(AppTheme.forLocale(newLocale));
    AppStorage.write(_storageKey, newLocale.languageCode);
    update();
  }

  void switchToEnglish() => switchTo(const Locale('en', 'US'));
  void switchToFarsi() => switchTo(const Locale('fa', 'IR'));
}
