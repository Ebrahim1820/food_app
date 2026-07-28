// Dev-only entry point for the Customer Experience team: runs the app with
// only Shared + Customer routes/controllers registered (no Seller/Admin
// code loaded at all) — faster local iteration, and doubles as a real check
// that customer_experience doesn't secretly depend on seller_mgmt/
// admin_platform. Run with: flutter run -t lib/main_customer.dart
//
// Production still ships lib/main.dart (all teams combined) — see its doc
// comment. A logged-in seller/admin account will hit "route not found"
// here, since AuthGate redirects by role and this build doesn't register
// those routes; that's expected for a scoped dev build.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_app/bindings/core_binding.dart';
import 'package:food_app/bindings/customer_binding.dart';
import 'package:food_app/routes/customer_pages.dart';
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

  runApp(const CustomerDevApp());
}

class CustomerDevApp extends StatelessWidget {
  const CustomerDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = Get.put(LocaleController());
    return Obx(
      () => GetMaterialApp(
        title: 'Perka — Customer (dev)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.forLocale(localeCtrl.locale.value),
        translations: AppTranslations(),
        locale: localeCtrl.locale.value,
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: BindingsBuilder(() {
          CoreBinding.register();
          CustomerBinding.register();
        }),
        initialRoute: AppRoutes.splash,
        getPages: [...SharedPages.pages, ...CustomerPages.pages],
      ),
    );
  }
}
