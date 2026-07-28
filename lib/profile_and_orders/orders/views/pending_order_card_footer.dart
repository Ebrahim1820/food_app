import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/orders/views/cancel_reason_dialog.dart';
import 'package:food_app/profile_and_orders/profile/views/icon_action_button.dart';
import 'package:food_app/theme/app_colors.dart';

/// Icon-only edit/cancel actions for a pending order's row on the "My
/// Orders" list — shared by Food's `OrderSummaryCard` and Cosmetic's
/// `CosmeticOrderCard` so both markets' list cards read as one design.
/// Food used to show a full-width labeled "Edit Order" button here; this
/// replaces it with the same compact icon style as Cancel for a cleaner
/// card, and gives Cosmetic (which had no actions on its list card at all)
/// the same footer.
class PendingOrderCardFooter extends StatelessWidget {
  const PendingOrderCardFooter({
    super.key,
    required this.orderId,
    required this.onEdit,
    required this.onCancel,
  });

  final String orderId;
  final VoidCallback onEdit;

  /// Called with the confirmed cancellation reason (empty string if the
  /// user skipped it). Not called at all if the user dismisses the dialog.
  final Future<void> Function(String? reason) onCancel;

  Future<void> _confirmCancel(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelReasonDialog(orderId: orderId),
    );
    // null → user dismissed without confirming; any String → confirmed.
    if (reason != null) {
      await onCancel(reason.isEmpty ? null : reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconActionButton(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              IconActionButton(
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                onTap: () => _confirmCancel(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
