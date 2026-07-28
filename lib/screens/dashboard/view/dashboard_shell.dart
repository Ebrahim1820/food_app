import 'package:flutter/material.dart';
import 'package:food_app/screens/dashboard/view/shell_app_bar.dart';
import 'package:design_system/design_system.dart';

/// Shared chrome for the app's market-facing shells (customer, business,
/// cosmetic, and any future market). Centralises the mechanics that were
/// previously duplicated across `MainNavigationScreen`, `BusinessDashboardScreen`
/// and `CosmeticCustomerHomeScreen` — RTL-aware drawer wiring, the
/// hamburger/dashboard/language/notification action row, and the shell's
/// look — while leaving each screen's body content fully parameterised.
///
/// Perka locked-shell rule: the AppBar and BottomNav are always
/// [AppColors.shellBackground] (Deep Royal Indigo), identical on every
/// screen regardless of market — this is deliberate for brand identity and
/// checkout trust, and callers should not override it per market. Per-market
/// colour (food orange, cosmetic violet, clothes charcoal — see
/// `market_colors.dart`) belongs on in-page CTAs/chips/badges instead, never
/// on the shell itself. [appBarBackgroundColor] still exists as an escape
/// hatch for genuinely non-market shells (e.g. Admin), not for per-market
/// variation.
///
/// This shell owns Scaffold/AppBar/Drawer construction only — each caller
/// still owns its own tab-index controller and body/bottom-nav content,
/// passed straight through as [body]/[bottomNavigationBar] unchanged.
/// [GlobalBottomNav]/`ScrollableBusinessNav` both style the locked shell
/// colours + Perka's gold active-tab highlight themselves now (neither is
/// built on Material's `NavigationBar`, so there's no shared ambient theme
/// to apply here anymore).
class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.marketKey,
    required this.body,
    this.appBarBackgroundColor,
    this.appBarForegroundColor = AppColors.white,
    this.greeting,
    this.title,
    this.subtitle,
    this.searchBar,
    this.extraActions = const [],
    this.drawer,
    this.leadingBuilder,
    this.leading,
    this.bottomNavigationBar,
    this.onDashboardTap,
    this.resizeToAvoidBottomInset = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.backgroundColor,
    this.showLanguageSwitcher = true,
    this.showNotificationBell = true,
    this.showCartButton = false,
    this.appBarElevation = 0.5,
  });

  /// Backend market key ('food' / 'cosmetic' / 'clothes' / ...) — passed
  /// through for callers that still want it for their own body content;
  /// no longer used internally to colour the shell itself (see class doc).
  final String marketKey;

  final Widget body;

  /// Defaults to [AppColors.shellBackground] (the Perka locked shell) — only
  /// override for a genuinely non-market shell (e.g. Admin's navy bar), not
  /// for per-market variation.
  final Color? appBarBackgroundColor;
  final Color appBarForegroundColor;

  /// Row 1's small "Hello, X 👋" text, next to the avatar. Widget (not a
  /// String) so callers can pass [GreetingHeader], which leaves its own
  /// color unset to inherit the style [ShellAppBar] applies. Null hides it.
  final Widget? greeting;

  /// Row 2's big heading (e.g. "PerkaFood") — styled by [ShellAppBar] itself
  /// (white, bold, 24px) so every screen's heading looks identical rather
  /// than trusting each caller's own TextStyle. Null renders no heading.
  final String? title;

  /// Row 2's small tagline below [title] (e.g. "Find Fresh Foods"). Row 2's
  /// height stays constant whether this is null or not.
  final String? subtitle;

  /// Perka's AppBar bottom row — a full-width search field. Null (the
  /// default) renders no second row, e.g. for shells that put search
  /// elsewhere in the body, or don't need it at all. Pass an [AppSearchField]
  /// for the standard look.
  final Widget? searchBar;

  /// Extra actions inserted between the dashboard button and the language
  /// switcher — e.g. business's open/closed toggle.
  final List<Widget> extraActions;

  /// Shared drawer content; the shell handles LTR/RTL side + edge-drag width.
  /// Null disables the drawer and hamburger button entirely (Cosmetics).
  final Widget? drawer;

  /// Overrides the default plain menu icon with a custom leading widget
  /// (e.g. customer's circular avatar) — receives the correct RTL-aware
  /// open-drawer callback to invoke on tap.
  final Widget Function(VoidCallback openDrawer)? leadingBuilder;

  /// Overrides [drawer]/[leadingBuilder] entirely with a fixed leading
  /// widget (e.g. a back button) — for a pushed detail screen that wants
  /// this shell's look/bottom nav but isn't itself a drawer/tab screen.
  final Widget? leading;

  final Widget? bottomNavigationBar;

  /// Null hides the dashboard/grid button.
  final VoidCallback? onDashboardTap;

  final bool resizeToAvoidBottomInset;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  /// Scaffold background — null keeps the app's theme default.
  final Color? backgroundColor;

  /// Both default to true (matching the 3 market shells); a non-market shell
  /// like Admin that wants neither icon in its action row sets these false
  /// rather than getting them unconditionally.
  final bool showLanguageSwitcher;
  final bool showNotificationBell;

  /// Off by default — only the customer-facing shell (Food/Cosmetic) passes
  /// true; business and admin dashboards share this same shell but have no
  /// customer cart to show.
  final bool showCartButton;

  /// Business's original AppBar already used 0.5 (a subtle shadow); Food's
  /// and Cosmetic's originals were both flat (elevation 0) — pass 0
  /// explicitly for any shell that shouldn't show that shadow.
  final double appBarElevation;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final resolvedAppBarColor =
        appBarBackgroundColor ?? AppColors.shellBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer == null ? null : (isRtl ? null : drawer),
      endDrawer: drawer == null ? null : (isRtl ? drawer : null),
      drawerEdgeDragWidth: isRtl ? 0 : 60,
      appBar: ShellAppBar(
        backgroundColor: resolvedAppBarColor,
        foregroundColor: appBarForegroundColor,
        elevation: appBarElevation,
        hasDrawer: drawer != null,
        leadingBuilder: leadingBuilder,
        leading: leading,
        greeting: greeting,
        title: title,
        subtitle: subtitle,
        searchBar: searchBar,
        onDashboardTap: onDashboardTap,
        extraActions: extraActions,
        showLanguageSwitcher: showLanguageSwitcher,
        showNotificationBell: showNotificationBell,
        showCartButton: showCartButton,
      ),
      body: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
