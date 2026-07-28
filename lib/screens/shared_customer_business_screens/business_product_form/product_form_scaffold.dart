import 'package:flutter/material.dart';

import 'package:food_app/theme/app_colors.dart';

/// Shared responsive shell for the business "create/edit listing" forms
/// (Food and Cosmetic today, any future market next). Centralizes the one
/// place device-responsive layout needs to live for these screens:
///
/// - Narrow (`< 700px`, the same breakpoint already used for the one other
///   responsive check in the app — `business_dashboard_screen.dart`):
///   single-column, scrollable, exactly like every existing create/edit
///   screen today.
/// - Wide (`>= 700px`, tablets/landscape): a two-pane layout — [photoSlot]
///   on the left, [fields] stacked on the right — instead of everything
///   stacked in one long column.
///
/// Safe-area and keyboard handling reuse the pattern already proven in
/// `create_food_offer_screen.dart`: [bottomBar] (typically a
/// `PrimaryActionFab`) already wraps itself in `SafeArea`, and the
/// scrollable body pads its bottom by `MediaQuery.paddingOf(context).bottom`
/// so content never sits under it. Keyboard avoidance is left to the
/// `Scaffold` default (`resizeToAvoidBottomInset: true`) plus the
/// scroll-into-view behavior every `TextFormField` already gets for free.
class ProductFormScaffold extends StatelessWidget {
  const ProductFormScaffold({
    super.key,
    required this.formKey,
    required this.appBarTitle,
    required this.photoSlot,
    required this.fields,
    required this.bottomBar,
    this.appBarActions,
  });

  final GlobalKey<FormState> formKey;
  final String appBarTitle;
  final Widget photoSlot;
  final List<Widget> fields;
  final Widget bottomBar;
  final List<Widget>? appBarActions;

  static const _wideBreakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        foregroundColor: AppColors.navy,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: appBarActions,
      ),
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomPadding = MediaQuery.paddingOf(context).bottom + 20;
              if (constraints.maxWidth >= _wideBreakpoint) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 280, child: photoSlot),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _withSpacing(fields),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
                children: [
                  photoSlot,
                  const SizedBox(height: 20),
                  ..._withSpacing(fields),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    final out = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      out.add(widgets[i]);
      if (i != widgets.length - 1) out.add(const SizedBox(height: 16));
    }
    return out;
  }
}
