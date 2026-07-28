import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_navigation_controller.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:food_app/controllers/notification_controller.dart';
import 'package:food_app/models/notification_model.dart';
import 'package:food_app/routes/app_routes.dart';
import 'package:food_app/services/push_notification_service.dart';
import 'package:food_app/strings/notifications_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/screens/dashboard/view/dashboard_shell.dart';
import 'package:food_app/screens/dashboard/view/global_bottom_nav.dart';
import 'package:food_app/screens/food_teil/business_views/scrollable_business_nav.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/empty_state_widget.dart';
import 'package:food_app/widgets/notification/notification_card.dart';
import 'package:get/get.dart';

/// Notification history for both customer and business-partner accounts.
/// Tapping a row marks it read and routes to whatever it's about (order,
/// offer, ...) via PushNotificationService's existing navigation logic, so a
/// tap here lands in exactly the same place as tapping the original push.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _ctrl = Get.find<NotificationController>();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl.fetchNotifications();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_ctrl.loadingMore.value || !_ctrl.hasMore.value) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _ctrl.fetchNotifications(loadMore: true);
    }
  }

  Future<void> _onTapNotification(NotificationModel n) async {
    _ctrl.markAsRead(n);
    final push = Get.find<PushNotificationService>();
    switch (n.type) {
      case 'new_order':
      case 'order_status_changed':
        final orderId = _idFromIri(n.data?['orderId']);
        if (orderId != null) await push.openOrder(orderId);
      case 'new_offer':
      case 'favorite_available':
        final offerId = int.tryParse(_idFromIri(n.data?['offerId']) ?? '');
        if (offerId != null) await push.openOffer(offerId);
    }
  }

  /// `data` values on a persisted notification are API IRIs
  /// (e.g. `"/api/orders/122"`), not bare ids — unlike the raw FCM push
  /// payload, which already sends bare ids and is handled separately in
  /// PushNotificationService. Strips everything up to and including the
  /// last `/` so both shapes end up usable the same way; a value with no
  /// `/` (a bare id) passes through unchanged.
  String? _idFromIri(Object? value) {
    final s = value?.toString();
    if (s == null || s.isEmpty) return null;
    final i = s.lastIndexOf('/');
    return i == -1 ? s : s.substring(i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return DashboardShell(
      marketKey: 'notifications',
      // Same AppBar/BottomNav look as everywhere else — only the body
      // background stays dark, so this still reads like a native OS
      // notification center against the rest of the app's light theme.
      backgroundColor: AppColors.gray900,
      appBarElevation: 0,
      safeAreaTop: false,
      safeAreaBottom: false,
      // Pushed on top of a shell rather than being a tab itself, so it needs
      // a plain back button, not the drawer hamburger every tab shell shows.
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppColors.white,
        ),
        onPressed: Get.back,
      ),
      title: NotificationsStrings.appBarTitle,
      showNotificationBell: false, // a bell action on the bell's own screen
      extraActions: [
        Obx(
          () => _ctrl.unreadCount.value > 0
              ? CustomDynamicButton(
                  label: NotificationsStrings.markAllRead,
                  onPressed: _ctrl.markAllAsRead,
                  variant: CustomButtonVariant.text,
                  accentColor: AppColors.success,
                )
              : const SizedBox.shrink(),
        ),
      ],
      bottomNavigationBar: _buildBottomNav(context),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.notifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(AppColors.success),
            ),
          );
        }

        if (_ctrl.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _ctrl.fetchNotifications(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 16, 20, safe.bottom + 24),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  // EmptyStateWidget is styled for the app's usual light
                  // background — wrap it in a light card rather than editing
                  // the shared widget, so it stays legible on this screen's
                  // intentionally dark backdrop.
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: EmptyStateWidget(
                        icon: Icons.notifications_none_rounded,
                        title: NotificationsStrings.emptyTitle,
                        subtitle: NotificationsStrings.emptySubtitle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final horizontalPadding = EdgeInsets.fromLTRB(
          safe.left + 16,
          16,
          safe.right + 16,
          safe.bottom + 24,
        );

        return RefreshIndicator(
          onRefresh: () => _ctrl.fetchNotifications(),
          child: isLandscape
              ? _buildGrid(horizontalPadding)
              : _buildList(horizontalPadding),
        );
      }),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────
  //
  // This screen is pushed on top of whichever shell it's opened from (via
  // Get.toNamed(AppRoutes.notifications) from the bell icon in either
  // AppShellScreen or BusinessDashboardScreen), so without this the only way
  // back is the AppBar's back arrow — no way to jump straight to another
  // main tab. Reuses that shell's own real bottom nav widget directly (not a
  // hand-copied mirror) so it's pixel-identical, and tapping a tab both
  // selects it and returns to the shell where it's actually rendered.
  //
  // NOTE: this can't be gated on `Get.isRegistered<BusinessPartnerController>()`
  // — InitialBinding.dependencies() calls Get.lazyPut for EVERY controller
  // for EVERY user regardless of role (confirmed in get-4.7.3's source:
  // lazyPut inserts into the instance map immediately, not just once
  // actually used), so that check is always true and would always hide
  // whichever branch used it. Get.previousRoute is the one reliable signal
  // here — NotificationBell only exists in these two shells
  // (app_shell_screen.dart, business_dashboard_screen.dart), both push
  // straight to /notifications, so whichever shell opened this screen is
  // exactly what's on top of it.
  Widget? _buildBottomNav(BuildContext context) {
    // Both names can be the shell's current route depending on entry path
    // (dashboard on fresh login, mainNavigation after some business flows
    // that Get.offAllNamed into it) — see AppRoutes' doc comment.
    if (Get.previousRoute == AppRoutes.mainNavigation ||
        Get.previousRoute == AppRoutes.dashboard) {
      return _buildCustomerBottomNav();
    }
    if (Get.previousRoute == AppRoutes.businessDashboard) {
      return _buildBusinessBottomNav(context);
    }
    return null;
  }

  Widget _buildCustomerBottomNav() {
    final navController = Get.find<NavigationController>();

    void selectTab(int i) {
      navController.currentIndex.value = i;
      Get.until(
        (route) =>
            route.settings.name == AppRoutes.mainNavigation ||
            route.settings.name == AppRoutes.dashboard,
      );
    }

    void goToDashboard() {
      navController.activeMarket.value = null;
      navController.currentIndex.value = 0;
      Get.until(
        (route) =>
            route.settings.name == AppRoutes.mainNavigation ||
            route.settings.name == AppRoutes.dashboard,
      );
    }

    // No tab here is really "selected" — this screen sits outside all of
    // them — but GlobalBottomNav requires an index, and highlighting
    // whichever tab currentIndex last pointed to (rather than always Home)
    // keeps it consistent with the shell you'll land back on.
    return Obx(
      () => GlobalBottomNav(
        selectedIndex: navController.currentIndex.value,
        activeMarket: navController.activeMarket.value,
        onDestinationSelected: selectTab,
        onDashboardTap: goToDashboard,
      ),
    );
  }

  // BusinessDashboardScreen only shows a bottom bar on narrow (phone) widths
  // — wide screens use a sidebar instead. Mirror that here too rather than
  // showing a bottom bar the dashboard itself never would.
  Widget? _buildBusinessBottomNav(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 600;
    if (wide) return null;

    final bizNavController = Get.find<BusinessNavigationController>();

    return Obx(
      () => ScrollableBusinessNav(
        selectedIndex: bizNavController.currentIndex.value,
        onSelect: (i) {
          bizNavController.currentIndex.value = i;
          Get.until(
            (route) => route.settings.name == AppRoutes.businessDashboard,
          );
        },
      ),
    );
  }

  Widget _buildList(EdgeInsets padding) {
    return ListView.separated(
      controller: _scrollCtrl,
      padding: padding,
      itemCount: _ctrl.notifications.length + (_ctrl.loadingMore.value ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildItem(index),
    );
  }

  // Landscape: two cards per row make better use of the extra width than one
  // long single-column list stretched edge-to-edge.
  Widget _buildGrid(EdgeInsets padding) {
    return GridView.builder(
      controller: _scrollCtrl,
      padding: padding,
      itemCount: _ctrl.notifications.length + (_ctrl.loadingMore.value ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 14,
        mainAxisExtent: 96,
      ),
      itemBuilder: (context, index) => _buildItem(index),
    );
  }

  Widget _buildItem(int index) {
    if (index >= _ctrl.notifications.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(AppColors.success),
          ),
        ),
      );
    }
    final n = _ctrl.notifications[index];
    return NotificationCard(
      notification: n,
      onTap: () => _onTapNotification(n),
    );
  }
}
