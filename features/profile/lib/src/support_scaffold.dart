import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// Shared scaffold used by all three support screens (Live Chat, Email, Call Us).
///
/// Provides a consistent AppBar (back button, white title, no elevation) and
/// sets the standard background colour. The [body] is rendered as-is — callers
/// are responsible for their own scroll / safe-area strategy.
class SupportScaffold extends StatelessWidget {
  const SupportScaffold({
    super.key,
    required this.appBarColor,
    required this.titleWidget,
    required this.body,
    this.centerTitle = true,
    this.actions,
  });

  final Color appBarColor;

  /// Widget shown as the AppBar title — pass a plain [Text] or a [Row] for
  /// landscape-specific agent info (Live Chat).
  final Widget titleWidget;

  final Widget body;
  final bool centerTitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: titleWidget,
        centerTitle: centerTitle,
        actions: actions,
      ),
      body: body,
    );
  }
}
