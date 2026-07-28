import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_app/bindings/initial_binding.dart';
import 'package:food_app/controllers/locale_controller.dart';
import 'package:food_app/l10n/app_translations.dart';
import 'package:food_app/routes/app_pages.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/services/app_storage.dart';
import 'package:food_app/theme/app_theme.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase and AppStorage (Hive) are independent — run them in parallel.
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    AppStorage.init(),
  ]);

  // resolveDevHost() is intentionally NOT awaited here.
  // It runs inside the splash screen's _bootstrap() concurrently with the
  // animation delay, so it never blocks the first rendered frame.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = Get.put(LocaleController());
    return Obx(
      () => GetMaterialApp(
        title: 'Perka App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.forLocale(localeCtrl.locale.value),
        translations: AppTranslations(),
        locale: localeCtrl.locale.value,
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: InitialBinding(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
      ),
    );
  }
}
