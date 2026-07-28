import 'package:admin_platform/admin_platform.dart';
import 'package:get/get.dart';

import 'core_binding.dart';

/// Trust & Ops team's admin controllers. Depends on [CoreBinding.apiService]
/// (call [CoreBinding.register] first).
class AdminBinding {
  static void register() {
    Get.lazyPut<AdminController>(
      () => AdminController(AdminService(CoreBinding.apiService)),
      fenix: true,
    );
  }

  static void clear() {
    Get.delete<AdminController>(force: true);
  }
}
