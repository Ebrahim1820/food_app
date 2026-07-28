import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:auth/auth.dart';
import 'package:food_app/controllers/navigation_controller.dart';
import 'package:food_app/widgets/common/app_search_field.dart';
import 'package:seller_mgmt/seller_mgmt.dart';
import 'package:food_app/screens/food_teil/business_views/business_notifications_screen.dart';
import 'package:food_app/screens/food_teil/business_views/business_security_screen.dart';
import 'package:core/core.dart';
import 'package:food_app/screens/dashboard/view/dashboard_shell.dart';
import 'package:food_app/widgets/logout_widget.dart';
import 'package:get/get.dart';

import 'package:i18n/i18n.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:seller_mgmt/src/business_views/business_reviews_screen.dart';

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------
class BusinessDashboardScreen extends StatefulWidget {
  final String businessName;
  const BusinessDashboardScreen({super.key, required this.businessName});

  @override
  State<BusinessDashboardScreen> createState() => _PartnerDashboardHomeState();
}

class _PartnerDashboardHomeState extends State<BusinessDashboardScreen> {
  // _isOpen is no longer local state — it is read from BusinessPartnerController
  // so the toggle reflects the real server value on every session.
  // Reactive so Obx rebuilds automatically when the tab changes.
  //
  // Sourced from BusinessNavigationController (not local State) so a screen
  // pushed on top of this one — e.g. NotificationsScreen's bottom nav — can
  // also select a tab to land back on, the same way NavigationController
  // already works for the customer shell.
  RxInt get _navIndex => Get.find<BusinessNavigationController>().currentIndex;
  int _prevNavIndex = 0;
  final AuthController authController = Get.find();
  final _bpCtrl = Get.find<BusinessPartnerController>();
  late final Worker _navWorker;

  /// Perka shell search bar — a launcher, not a live filter: tapping it jumps
  /// to the Menu tab (index 2), which already has its own real search via
  /// [BusinessOfferController]/[SearchFilterBar]. Not reusing that live
  /// state here directly since the Dashboard/Overview tab isn't a list of
  /// offers to filter in place.
  final _dashboardSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch fresh orders every time the user navigates to the Orders tab.
    // IndexedStack keeps BusinessOrdersScreen alive so initState on that screen
    // only fires once — this worker is the only reliable trigger on tab switch.
    _navWorker = ever(_navIndex, (int index) {
      if (index == 0 || index == 1) {
        Get.find<BusinessOrderController>().fetchOrders();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.find<BusinessOrderController>().fetchOrders(),
    );
  }

  @override
  void dispose() {
    _navWorker.dispose();
    _dashboardSearchCtrl.dispose();
    super.dispose();
  }

  /// Sends the open/closed change to the backend and shows a snackbar on error.
  Future<void> _toggleOpenClosed(bool isOpen) async {
    final ok = await _bpCtrl.setIsOpen(isOpen);
    if (!ok && mounted) {
      AppSnackbar.error(
        BusinessDashboardStrings.couldNotUpdateStatus,
        _bpCtrl.fetchError.value ?? BusinessDashboardStrings.checkConnection,
      );
    }
  }

  void _handleMenu(String value) {
    switch (value) {
      case 'business_profile':
        Get.to(() => const BusinessProfileScreen());
      case 'bank_account':
        Get.to(() => const BusinessBankAccountScreen());
      case 'operating_hours':
        Get.to(() => const BusinessOperatingHoursScreen());
      case 'photos_branding':
        Get.to(() => const BusinessPhotosScreen());
      case 'locations':
        Get.to(() => const BusinessAddressesScreen());
      case 'team_members':
        _openTeamMembers();
      case 'push_notifications':
        Get.to(() => const BusinessNotificationsScreen());
      case 'email_alerts':
        Get.to(() => const BusinessEmailAlertsScreen());
      case 'security':
        Get.to(() => const BusinessSecurityScreen());
      case 'help':
        Get.to(() => const BusinessHelpScreen());
      case 'about':
        Get.to(() => const BusinessAboutScreen());
      case 'settings':
        Get.to(
          () => BusinessSettingsScreen(
            onOpenNotifications: () =>
                Get.to(() => const BusinessNotificationsScreen()),
            onOpenSecurity: () => Get.to(() => const BusinessSecurityScreen()),
          ),
        );
    }
  }

  void _openTeamMembers() {
    if (!authController.isBusinessPartner) return;
    _prevNavIndex = _navIndex.value;
    _navIndex.value = 6;
  }

  /// Returns to the Dashboard's market tiles — NOT to whatever customer
  /// page (Food/Cosmetics browse, Favorites, ...) AppShellScreen's
  /// NavigationController last pointed to. That state is a persistent
  /// singleton independent of this screen, so without resetting it here,
  /// `Get.offNamed(AppRoutes.dashboard)` would land back on stale customer
  /// content instead of the bare tile picker.
  void _goToDashboard() {
    final nav = Get.find<NavigationController>();
    nav.activeMarket.value = null;
    nav.currentIndex.value = 0;
    Get.offNamed(AppRoutes.dashboard);
  }

  /// "Switch to customer view" — lets an owner/staff member browse and buy
  /// from *other* stores as a plain customer instead of always landing back
  /// on their own Business Dashboard (see DashboardController.onTileTap).
  void _switchToCustomerView() {
    Get.back(); // close the drawer — AppDrawer's role badge doesn't auto-pop
    final nav = Get.find<NavigationController>();
    nav.actingAsCustomer.value = true;
    nav.activeMarket.value = null;
    nav.currentIndex.value = 0;
    Get.offNamed(AppRoutes.dashboard);
  }

  Widget _buildDrawer() {
    return Obx(() {
      final bpCtrl = Get.find<BusinessPartnerController>();
      final partner = bpCtrl.partner.value;
      final initials = partner?.businessName.isNotEmpty == true
          ? partner!.businessName.characters.first.toUpperCase()
          : '?';
      return AppDrawer(
        footer: const LogoutWidget(),
        avatarWidget: UploadableAvatar(
          initials: initials,
          imageType: 'business_logo',
          partnerIri: partner?.iri,
          uploadPartnerIri: partner?.iri,
          size: 52,
          canUpload: true,
          backgroundColor: AppColors.white.withValues(alpha: 0.25),
          initialsColor: AppColors.white,
        ),
        userToken: authController.accessToken.value,
        roleBadge: authController.isBusinessPartner
            ? 'biz_drawer_ownerBadge'.tr
            : 'biz_drawer_memberBadge'.tr,
        onRoleBadgeTap: _switchToCustomerView,
        onMenuSelected: _handleMenu,
        sections: [
          DrawerSection(
            label: 'biz_drawer_sectionBusiness'.tr,
            items: [
              // The full profile PATCH (name, contact info, cash-payment
              // toggle, delivery fee) is owner-only on the backend — staff
              // only get the separate toggle-active (open/closed) switch
              // elsewhere on the dashboard. Hide the entry instead of
              // letting staff open a screen full of controls that 403.
              if (authController.isBusinessPartner)
                DrawerItem(
                  icon: Icons.store_outlined,
                  label: 'biz_drawer_businessProfile'.tr,
                  value: 'business_profile',
                ),
              // GET /business_bank_accounts is owner-only on the backend now —
              // hide the entry for staff (ROLE_MEMBER) instead of letting them
              // tap in and hit a 403.
              if (authController.isBusinessPartner)
                DrawerItem(
                  icon: Icons.account_balance_outlined,
                  label: 'biz_drawer_bankAccountsAndPayment'.tr,
                  value: 'bank_account',
                  iconColor: AppColors.accentDark,
                ),
              DrawerItem(
                icon: Icons.schedule_outlined,
                label: 'biz_drawer_operatingHours'.tr,
                value: 'operating_hours',
                iconColor: AppColors.infoDark,
              ),
              DrawerItem(
                icon: Icons.photo_camera_outlined,
                label: 'biz_drawer_photosBranding'.tr,
                value: 'photos_branding',
                iconColor: AppColors.pink,
              ),
              DrawerItem(
                icon: Icons.location_on_outlined,
                label: 'biz_drawer_locations'.tr,
                value: 'locations',
                iconColor: AppColors.error,
              ),
            ],
          ),
          if (authController.isBusinessPartner)
            DrawerSection(
              label: 'biz_drawer_sectionTeam'.tr,
              items: [
                DrawerItem(
                  icon: Icons.group_outlined,
                  label: 'biz_drawer_teamMembers'.tr,
                  value: 'team_members',
                  iconColor: AppColors.purple,
                ),
              ],
            ),
          DrawerSection(
            label: 'biz_drawer_sectionAccount'.tr,
            items: [
              DrawerItem(
                icon: Icons.settings_outlined,
                label: 'partner_settings'.tr,
                value: 'settings',
                iconColor: AppColors.gray500,
              ),
            ],
          ),
        ],
      );
    });
  }

  // ── KPI cards — values will be replaced with real API data. ──────────────
  List<MetricModel> get _metrics => [
    MetricModel(
      BusinessDashboardStrings.metricTodaysRevenue,
      '—',
      '—',
      Icons.payments_outlined,
      AppColors.successDark,
    ),
    MetricModel(
      BusinessDashboardStrings.metricOrdersToday,
      '—',
      '—',
      Icons.receipt_long_outlined,
      AppColors.infoDark,
    ),
    MetricModel(
      BusinessDashboardStrings.metricAvgOrderValue,
      '—',
      '—',
      Icons.trending_up,
      AppColors.purple,
    ),
    MetricModel(
      BusinessDashboardStrings.metricRating,
      '—',
      '—',
      Icons.star_outline,
      AppColors.warningDeep,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 600;

    return DashboardShell(
      // Perka locked shell — AppBar is always AppColors.shellBackground
      // (Deep Royal Indigo), same as every other screen. Was previously a
      // white AppBar with navy text; removing that override is the entire
      // change here.
      marketKey: 'food',
      searchBar: AppSearchField(
        controller: _dashboardSearchCtrl,
        hint: 'Search your menu...',
        readOnly: true,
        onTap: () => _navIndex.value = 2, // jump to Menu tab's real search
      ),
      drawer: _buildDrawer(),
      leadingBuilder: (openDrawer) => Obx(() {
        final partner = Get.find<BusinessPartnerController>().partner.value;
        final initials = partner?.businessName.isNotEmpty == true
            ? partner!.businessName.characters.first.toUpperCase()
            : '?';
        return UploadableAvatar(
          initials: initials,
          imageType: 'business_logo',
          partnerIri: partner?.iri,
          uploadPartnerIri: partner?.iri,
          size: 38,
          canUpload: false,
          backgroundColor: AppColors.white,
          initialsColor: AppColors.shellBackground,
          onTap: openDrawer,
        );
      }),
      onDashboardTap: _goToDashboard,
      extraActions: [
        Obx(() {
          final isOpen = _bpCtrl.partner.value?.isActive ?? true;
          final isUpdating = _bpCtrl.isTogglingStatus.value;
          return _OpenClosedToggle(
            isOpen: isOpen,
            isUpdating: isUpdating,
            onChanged: _toggleOpenClosed,
          );
        }),
        const SizedBox(width: 8),
      ],
      safeAreaTop: false,
      safeAreaBottom: false,
      // Sidebar on wide screens, bottom nav on phones.
      // Obx ensures IndexedStack rebuilds with the correct businessPartnerId
      // once fetchMyPartner() completes (partner starts as null/0).
      body: Obx(
        () => Row(
          children: [
            if (wide) _buildSidebar(),
            Expanded(child: _buildContent(wide)),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : Obx(
              () => ScrollableBusinessNav(
                selectedIndex: _navIndex.value,
                onSelect: (i) => _navIndex.value = i,
              ),
            ),
    );
  }

  // --- sidebar -----------------------------------------------------------
  Widget _buildSidebar() {
    final navItems = <(IconData, String, int)>[
      (Icons.dashboard_outlined, 'biz_nav_overview'.tr, 0),
      (Icons.receipt_long_outlined, 'biz_nav_orders'.tr, 1),
      (Icons.restaurant_menu_outlined, 'biz_nav_menu'.tr, 2),
      (Icons.bar_chart_outlined, 'biz_nav_analytics'.tr, 3),
      (Icons.account_balance_wallet_outlined, 'biz_nav_earnings'.tr, 4),
      (Icons.reviews_outlined, 'biz_nav_reviews'.tr, 5),
    ];

    return Container(
      width: 220,
      color: AppColors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          ...navItems.map(
            (item) => _SidebarTile(
              icon: item.$1,
              label: item.$2,
              selected: _navIndex.value == item.$3,
              onTap: () => _navIndex.value = item.$3,
              showOrdersBadge: item.$3 == 1,
            ),
          ),
          // Settings — expandable with all sub-items
          // _SidebarSettingsTile(
          //   selected: _navIndex.value == 6,
          //   onTeamMembersTap: _openTeamMembers,
          // ),
        ],
      ),
    );
  }

  // --- main content (routes by selected nav index) ----------------------
  // IndexedStack builds every tab once and shows only the selected one, so
  // each tab keeps its state (scroll position, loaded orders) when you switch.
  Widget _buildContent(bool wide) {
    return IndexedStack(
      index: _navIndex.value,
      children: [
        _buildOverview(wide), // 0 Overview
        // 1 Orders — your real page.
        // TODO: replace these callbacks with your actual order-api /
        // controller methods. e.g. fetchOrders: () => Get.find<OrderController>().fetch()
        BusinessOrdersScreen(),

        // 2 Menu
        BusinessMenuScreen(
          businessPartnerId: Get.find<BusinessPartnerController>().partnerId,
        ),

        // 3 Analytics
        BusinessAnalyticsScreen(),

        const BusinessEarningsScreen(), // 4 Earnings
        const BusinessReviewsScreen(), // 5 Reviews
        TeamMembersScreen(
          // 6 Team Members
          onBack: () => _navIndex.value = _prevNavIndex,
        ),
      ],
    );
  }

  // --- overview tab (was _buildContent) ---------------------------------
  Widget _buildOverview(bool wide) {
    return Column(
      children: [
        // Sits above the tab's own 20px padding (like the other cached
        // screens' StaleBanner placement) so its built-in horizontal inset
        // doesn't stack with the padding below.
        Obx(
          () => _bpCtrl.isFromCache.value
              ? StaleBanner(onRefresh: _bpCtrl.fetchMyPartner)
              : const SizedBox.shrink(),
        ),
        Expanded(child: _buildOverviewContent()),
      ],
    );
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final partner = _bpCtrl.partner.value;
            final earningsCtrl = Get.find<BusinessEarningsController>();
            final today = earningsCtrl.currentData;
            return BusinessSummaryCard(
              businessName: widget.businessName,
              isOpen: partner?.isActive ?? true,
              todayEarnings: CurrencyFormatter.round(today.netEarnings),
              ordersToday: '—',
              rating: partner?.rating ?? 0,
              pendingPayout: CurrencyFormatter.round(today.pendingPayout),
              onRatingTap: () => _navIndex.value = 5,
            );
          }),
          const SizedBox(height: 16),

          // impact tracker
          Obx(
            () => ImpactHeroCard(
              stats: ImpactCalculator.fromOrders(
                Get.find<BusinessOrderController>().orders,
              ),
              subtitle: ImpactStrings.heroSubtitleBusiness,
              isLoading:
                  Get.find<BusinessOrderController>().isLoading.value &&
                  Get.find<BusinessOrderController>().orders.isEmpty,
              onTap: () => Get.to(() => const BusinessImpactScreen()),
            ),
          ),
          const SizedBox(height: 20),

          // metric cards (responsive grid)
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: _metrics.map(_metricCard).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // live orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'partner_liveOrders'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              CustomDynamicButton(
                label: 'partner_viewAll'.tr,
                onPressed: () => _navIndex.value = 1,
                variant: CustomButtonVariant.text,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final ctrl = Get.find<BusinessOrderController>();
            final active = ctrl.orders
                .where(
                  (o) => ![
                    'delivered',
                    'cancelled',
                    'completed',
                  ].contains(o.status),
                )
                .take(4)
                .toList();
            if (ctrl.isLoading.value && active.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (active.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      BusinessDashboardStrings.noActiveOrders,
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(children: active.map(_orderTile).toList());
          }),
        ],
      ),
    );
  }

  Widget _metricCard(MetricModel m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: m.color, size: 20),
              ),
            ],
          ),
          Text(
            m.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          Text(
            m.label,
            style: const TextStyle(color: AppColors.gray600, fontSize: 13),
          ),
          Text(
            m.delta,
            style: TextStyle(
              color: m.color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTile(OrderModel o) {
    final statusColor = switch (o.status) {
      'pending' => AppColors.primary,
      'confirmed' || 'preparing' => AppColors.infoDark,
      'ready' => AppColors.warningDeep,
      _ => AppColors.gray400,
    };
    final customerName = o.user?.fullName.isNotEmpty == true
        ? o.user!.fullName
        : 'Customer';
    final itemCount = o.orderItems.length;
    final total = double.tryParse(o.totalPrice) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${o.id}  ·  $customerName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '$itemCount item(s)  ·  ${_timeAgo(o.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          if (o.status == 'pending')
            CustomDynamicButton(
              label: 'bizCard_acceptButton'.tr,
              onPressed: () => _navIndex.value = 1,
              accentColor: statusColor,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                o.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    return '${diff.inHours}h ago';
  }
}

// ---------------------------------------------------------------------------
// Open / Closed toggle pill
// ---------------------------------------------------------------------------
class _OpenClosedToggle extends StatelessWidget {
  final bool isOpen;
  // True while the PATCH request is in-flight — shows a spinner instead of
  // the dot icon so the partner knows the change is being saved.
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  const _OpenClosedToggle({
    required this.isOpen,
    required this.isUpdating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.successDark : AppColors.warningDeep;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      // Disable tap while the PATCH is in-flight to prevent double-tapping.
      onTap: isUpdating ? null : () => onChanged(!isOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            // Spinner while saving, dot icon when idle.
            if (isUpdating)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              )
            else
              Icon(
                isOpen ? Icons.circle : Icons.circle_outlined,
                size: 12,
                color: color,
              ),
            const SizedBox(width: 6),
            Text(
              isOpen ? 'partner_open'.tr : 'partner_closed'.tr,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar — plain nav tile (reusable for all non-expandable items)
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showOrdersBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showOrdersBadge;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.successDark : AppColors.gray600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.infoLight : AppColors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: showOrdersBadge
              ? Obx(
                  () => NotificationDot(
                    show:
                        Get.isRegistered<BusinessOrderController>() &&
                        Get.find<BusinessOrderController>()
                            .hasNewOrActiveOrders,
                    child: Icon(icon, color: iconColor),
                  ),
                )
              : Icon(icon, color: iconColor),
          title: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.navy : AppColors.gray600,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar — Settings tile with expandable sub-menu
// ---------------------------------------------------------------------------
class _SidebarSettingsTile extends StatefulWidget {
  const _SidebarSettingsTile({
    required this.selected,
    required this.onTeamMembersTap,
  });

  final bool selected;
  final VoidCallback onTeamMembersTap;

  @override
  State<_SidebarSettingsTile> createState() => _SidebarSettingsTileState();
}

class _SidebarSettingsTileState extends State<_SidebarSettingsTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Theme(
        // Remove the default ExpansionTile divider lines
        data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: widget.selected
              ? AppColors.infoLight
              : AppColors.transparent,
          collapsedBackgroundColor: AppColors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            Icons.settings_outlined,
            color: widget.selected ? AppColors.successDark : AppColors.gray600,
          ),
          title: Text(
            'Settings',
            style: TextStyle(
              color: widget.selected ? AppColors.navy : AppColors.gray600,
              fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          children: [
            _SubMenuItem(
              icon: Icons.group_outlined,
              label: 'Team Members',
              onTap: widget.onTeamMembersTap,
            ),
            _SubMenuItem(
              icon: Icons.store_outlined,
              label: 'Business Profile',
              onTap: () {
                /* TODO */
              },
            ),
            _SubMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => Get.toNamed(AppRoutes.notifications),
            ),
            _SubMenuItem(
              icon: Icons.language_outlined,
              label: 'Language',
              onTap: () => Get.toNamed(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar — indented sub-menu item under an expandable tile
// ---------------------------------------------------------------------------
class _SubMenuItem extends StatelessWidget {
  const _SubMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 12),
      dense: true,
      leading: Icon(icon, size: 18, color: AppColors.gray500),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.gray600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
