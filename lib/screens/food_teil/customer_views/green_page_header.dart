import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

/// Green gradient header used on Home, Favorites, and Orders screens.
///
/// Renders a rounded-bottom gradient container with a white search field
/// inside. Wrap in [Obx] at the call site and pass the current [hasText]
/// value so the clear (×) button appears and disappears reactively.
///
/// ```dart
/// Obx(() => GreenPageHeader(
///   searchController: _ctrl,
///   hint: 'Search…',
///   hasText: rx.value.isNotEmpty,
///   onChanged: (v) => rx.value = v,
///   onClear: () { _ctrl.clear(); rx.value = ''; },
/// ))
/// ```
class GreenPageHeader extends StatelessWidget {
  const GreenPageHeader({
    super.key,
    this.title,
    this.subtitle,
    this.badge,
    required this.searchController,
    required this.hint,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  /// Optional bold title shown above the search field.
  final String? title;

  /// Optional muted line below the title.
  final String? subtitle;

  /// Optional count shown as a white pill next to the title.
  final String? badge;

  final TextEditingController searchController;
  final String hint;

  /// Whether the search field currently has text — controls clear-button visibility.
  final bool hasText;

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   //colors: [AppColors.primary, AppColors.primaryDark],
        // ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 14),
              child: Text(
                subtitle ?? '',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.80),
                  fontSize: 14,
                ),
              ),
            ),
          ] else
            const SizedBox.shrink(),
          _SearchField(
            controller: searchController,
            hint: hint,
            hasText: hasText,
            onChanged: onChanged,
            onClear: onClear,
          ),
        ],
      ),
    );
  }
}

// ── White search field rendered on the green background ──────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.gray400,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
