// Dev-only entry point for the Trust & Ops team: runs the app with only
// Shared + Admin routes/controllers registered. Run with:
// flutter run -t lib/main_admin.dart
//
// Production still ships lib/main.dart (all teams combined) — see its doc
// comment. A logged-in customer/seller account will hit "route not found"
// here, since AuthGate redirects by role and this build doesn't register
// those routes; that's expected for a scoped dev build.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_app/bindings/admin_binding.dart';
import 'package:food_app/bindings/core_binding.dart';
import 'package:food_app/routes/admin_pages.dart';
import 'package:food_app/routes/shared_pages.dart';
import 'package:i18n/i18n.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    AppStorage.init(),
  ]);

  runApp(const AdminDevApp());
}

class AdminDevApp extends StatelessWidget {
  const AdminDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = Get.put(LocaleController());
    return Obx(
      () => GetMaterialApp(
        title: 'Perka — Admin (dev)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.forLocale(localeCtrl.locale.value),
        translations: AppTranslations(),
        locale: localeCtrl.locale.value,
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: BindingsBuilder(() {
          CoreBinding.register();
          AdminBinding.register();
        }),
        initialRoute: AppRoutes.splash,
        getPages: [...SharedPages.pages, ...AdminPages.pages],
      ),
    );
  }
}
