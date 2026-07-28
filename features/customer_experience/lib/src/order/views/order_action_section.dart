import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:profile/profile.dart';

/// Edit/cancel actions for a pending order's detail screen — market-agnostic
/// so both Food and Cosmetic wire the same widget instead of Cosmetic having
/// none at all. A market wraps its own model, passes [canEdit]/[canCancel]
/// (driven by the shared `isPendingOrderStatus` helper) and its own
/// [onEdit]/[onCancel] callbacks, and can append market-specific extras
/// (Food's Reorder/RateOrderButton) via [extra].
class OrderActionsSection extends StatelessWidget {
  const OrderActionsSection({
    super.key,
    required this.orderId,
    required this.canEdit,
    required this.canCancel,
    this.onEdit,
    this.onCancel,
    this.extra,
  });

  final String orderId;
  final bool canEdit;
  final bool canCancel;
  final VoidCallback? onEdit;

  /// Called with the confirmed cancellation reason (empty string if the
  /// user skipped it). Not called at all if the user dismisses the dialog.
  final Future<void> Function(String? reason)? onCancel;

  /// Market-specific actions appended below edit/cancel (Food's
  /// Reorder/RateOrderButton) — omitted entirely for markets that don't
  /// have an equivalent yet.
  final Widget? extra;

  Future<void> _confirmCancel(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelReasonDialog(orderId: orderId),
    );
    // null → user dismissed without confirming; any String → confirmed.
    if (reason != null) {
      await onCancel?.call(reason.isEmpty ? null : reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (canEdit) ...[
            Row(
              children: [
                Expanded(
                  child: CustomDynamicButton(
                    fullWidth: true,
                    borderRadius: 14,
                    icon: Icons.edit_outlined,
                    label: CustomerOrderStrings.editOrderButton,
                    onPressed: onEdit,
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(width: 10),
                  IconActionButton(
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    onTap: () => _confirmCancel(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
          ?extra,
        ],
      ),
    );
  }
}
