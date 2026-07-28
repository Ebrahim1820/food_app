import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  /// Which market's content the shell's Home tab (index 0) is showing —
  /// null / 'food' / 'cosmetic' / ... Null means the bare Dashboard tiles.
  /// Single source of truth for AppShellScreen's Home body, header, and
  /// Hub-button visibility (see app_shell_screen.dart).
  final RxnString activeMarket = RxnString();

  /// True once a business-capable user (owner/staff) has explicitly chosen
  /// "switch to customer view" from the account drawer — lets them browse
  /// and buy from *other* stores as a plain customer instead of always
  /// being routed back to their own Business Dashboard. Reset to false when
  /// they switch back. Defaults false so nothing changes for anyone who
  /// never touches the toggle (matches AuthGate's default post-login
  /// redirect: business-capable users land on the Business Dashboard).
  final RxBool actingAsCustomer = false.obs;
}
