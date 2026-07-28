import 'package:get/get.dart';

/// Mirrors NavigationController but for the business-dashboard shell's own
/// tab set (Overview/Orders/Menu/Analytics/Earnings/Reviews). Needed so a
/// screen pushed on top of BusinessDashboardScreen (e.g. NotificationsScreen)
/// can select a tab to land on — the index used to be private State inside
/// BusinessDashboardScreen with nothing outside it able to reach in.
class BusinessNavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
}
