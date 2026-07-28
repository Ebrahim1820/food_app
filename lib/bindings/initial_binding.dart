import 'package:get/get.dart';

import 'admin_binding.dart';
import 'core_binding.dart';
import 'customer_binding.dart';
import 'seller_binding.dart';

/// GetX runs this once at app startup (wired via `initialBinding` in
/// main.dart). Delegates to each team's own binding — CoreBinding first
/// (auth + the shared HTTP client + services other bindings build on), then
/// CustomerBinding/SellerBinding/AdminBinding, each owned by its team. A PR
/// adding a controller touches only its team's binding file, not this one.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    CoreBinding.register();
    CustomerBinding.register();
    SellerBinding.register();
    AdminBinding.register();
  }

  /// Delete every user-scoped controller so that after logout the next
  /// `Get.find<T>()` recreates it fresh (calls onInit → fetchXxx) for the
  /// newly logged-in user. Safe to call even if a controller was never
  /// instantiated (`Get.delete` is a no-op for unknown types).
  static void clearUserControllers() {
    CoreBinding.clear();
    CustomerBinding.clear();
    SellerBinding.clear();
    AdminBinding.clear();
  }
}
