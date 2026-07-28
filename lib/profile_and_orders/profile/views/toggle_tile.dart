// A ListTile with a coloured rounded-square icon and a Switch trailing widget.
// Toggle state is held in a per-instance ValueNotifier so the widget stays
// StatelessWidget. Suitable for any settings-style toggle row.

import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

class ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ValueChanged<bool>? onChanged;

  // Instance-level ValueNotifier: no resources to leak, safe on StatelessWidget.
  final ValueNotifier<bool> _enabled;

  ToggleTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required bool initialValue,
    this.onChanged,
  }) : _enabled = ValueNotifier(initialValue);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ValueListenableBuilder<bool>(
        valueListenable: _enabled,
        builder: (context, value, child) {
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: AppColors.white,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Switch(
              value: value,
              onChanged: (v) {
                _enabled.value = v;
                onChanged?.call(v);
              },
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primaryLight,
            ),
          );
        },
      ),
    );
  }
}
