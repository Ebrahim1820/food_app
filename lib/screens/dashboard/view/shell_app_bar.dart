import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:food_app/screens/add_to_cart/views/cart_icon_button.dart';
import 'package:food_app/screens/dashboard/view/shell_leading_avatar_ring.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/widgets/common/notification_bell.dart';
import 'package:food_app/widgets/language_flag_switcher.dart';
import 'package:get/get.dart';

class ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellAppBar({
    super.key,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.elevation,
    this.greeting,
    this.title,
    this.subtitle,
    this.searchBar,
    this.hasDrawer = false,
    this.leadingBuilder,
    this.leading,
    this.onDashboardTap,
    this.extraActions = const [],
    this.showLanguageSwitcher = true,
    this.showNotificationBell = true,
    this.showCartButton = false,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;

  final Widget? greeting;
  final String? title;
  final String? subtitle;
  final Widget? searchBar;

  final bool hasDrawer;
  final Widget Function(VoidCallback openDrawer)? leadingBuilder;

  /// Overrides [hasDrawer]/[leadingBuilder] entirely with a fixed leading
  /// widget (e.g. a back button) — for pushed detail screens that use this
  /// shell's look but aren't part of the drawer/tab shell itself.
  final Widget? leading;

  final VoidCallback? onDashboardTap;
  final List<Widget> extraActions;

  final bool showLanguageSwitcher;
  final bool showNotificationBell;

  /// Off by default — only customer shells that actually have a cart
  /// (see `DashboardShell.showCartButton`) pass true; business/admin
  /// dashboards using this same shell never do.
  final bool showCartButton;

  static const double _bottomRadius = 24;

  /// Dynamically computes component row heights based on screen size and optional content
  _ShellAppBarHeights _calculateHeights(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Row 1: Utility row (min 44, max 50)
    final utilityHeight = (screenHeight * 0.055).clamp(44.0, 50.0);

    // Row 2: Title row (shrinks if subtitle is missing)
    final titleHeight = subtitle != null
        ? (screenHeight * 0.055).clamp(44.0, 58.0)
        : (screenHeight * 0.040).clamp(34.0, 44.0);

    // Row 3: Search row (0 if searchBar is null)
    final searchHeight = searchBar != null
        ? (screenHeight * 0.060).clamp(48.0, 56.0)
        : 0.0;

    return _ShellAppBarHeights(
      utilityHeight: utilityHeight,
      titleHeight: titleHeight,
      searchHeight: searchHeight,
    );
  }

  @override
  Size get preferredSize {
    // Dynamic height calculation reflecting real active slots
    final hasSearch = searchBar != null;
    final hasSub = subtitle != null;

    // Base total height calculation
    double totalHeight =
        48.0 + (hasSub ? 50.0 : 38.0) + (hasSearch ? 54.0 : 0.0);
    return Size.fromHeight(totalHeight);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final onDarkAppBar = foregroundColor == AppColors.white;
    final heights = _calculateHeights(context);

    final utilityRow = SizedBox(
      height: heights.utilityHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (hasDrawer)
                _buildLeading(context, isRtl, foregroundColor),
              if (greeting != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        child: greeting!,
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              if (onDashboardTap != null)
                IconButton(
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.grid_view_rounded, color: foregroundColor),
                  tooltip: 'shellAppBar_dashboardTooltip'.tr,
                  onPressed: onDashboardTap,
                ),
              for (final action in extraActions) ...[
                action,
                const SizedBox(width: 4),
              ],
              if (showLanguageSwitcher)
                LanguageFlagSwitcher(onDark: onDarkAppBar),
              if (showCartButton) ...[
                const SizedBox(width: 4),
                CartIconButton(iconColor: foregroundColor),
              ],
              if (showNotificationBell) ...[
                const SizedBox(width: 4),
                NotificationBell(iconColor: foregroundColor),
              ],
            ],
          ),
        ),
      ),
    );

    final titleRow = SizedBox(
      height: heights.titleHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min, // Do not expand vertically past constraints
          children: [
            if (title != null)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    title!,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          20, // Slightly reduced to guarantee headroom for subtitle
                      height: 1.1, // Tighten line height metric
                    ),
                  ),
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.shellForegroundMuted,
                      fontSize: 16,
                      height: 1, // Tighten line height metric
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // A bare Container (unlike a real AppBar) never tells the OS what
    // brightness the status/navigation bar icons should be, so they default
    // to whatever the previous screen left behind — invisible dark icons on
    // this shell's dark background. Derive it from the actual background
    // colour rather than [foregroundColor] so this stays correct even for
    // the light-bar escape hatch (e.g. Admin's [appBarBackgroundColor]).
    //
    // Only one SystemUiOverlayStyle governs the whole screen at a time (it
    // isn't spatially split top/bottom), so this single region also covers
    // the Android system navigation bar at the bottom — matching its colour
    // to [backgroundColor] since GlobalBottomNav is always painted in this
    // same locked shell colour (see DashboardShell's class doc).
    final isDarkShell =
        ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: isDarkShell ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDarkShell ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: backgroundColor,
      systemNavigationBarIconBrightness: isDarkShell
          ? Brightness.light
          : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(_bottomRadius),
          ),
          boxShadow: elevation <= 0
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black12,
                    blurRadius: elevation * 4,
                    offset: Offset(0, elevation * 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(_bottomRadius),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        utilityRow,
                        SizedBox(height: 4),
                        Row(children: [Expanded(child: titleRow)]),
                        if (searchBar != null)
                          SizedBox(
                            height: heights.searchHeight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                              child: searchBar,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext scaffoldCtx, bool isRtl, Color color) {
    void openDrawer() => isRtl
        ? Scaffold.of(scaffoldCtx).openEndDrawer()
        : Scaffold.of(scaffoldCtx).openDrawer();
    return leadingBuilder != null
        ? leadingBuilder!(openDrawer)
        : ShellLeadingAvatarRing(
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: openDrawer,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.white,
                child: Icon(
                  Icons.menu,
                  color: AppColors.shellBackground,
                  size: 16,
                ),
              ),
            ),
          );
  }
}

class _ShellAppBarHeights {
  final double utilityHeight;
  final double titleHeight;
  final double searchHeight;

  const _ShellAppBarHeights({
    required this.utilityHeight,
    required this.titleHeight,
    required this.searchHeight,
  });
}
