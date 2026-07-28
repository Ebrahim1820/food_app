import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:customer_experience/customer_experience.dart';

/// Cancellation-reason picker shown before cancelling a pending order.
/// Market-agnostic — only needs the order's display id (for the subtitle),
/// so both Food's and Cosmetic's order screens share this one dialog instead
/// of each keeping their own copy.
///
/// Returns `null` if the user dismissed without confirming; any `String`
/// (possibly empty) if they confirmed cancellation.
class CancelReasonDialog extends StatefulWidget {
  final String orderId;
  const CancelReasonDialog({super.key, required this.orderId});

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  List<String> get _presets => CustomerOrderStrings.cancellationReasons;

  String? _selected;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  String get _finalReason {
    if (_selected == null) return '';
    if (_selected == CustomerOrderStrings.cancellationReasonOther) {
      return _otherCtrl.text.trim();
    }
    return _selected!;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(color: AppColors.errorLight),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  CustomerOrderStrings.cancelDialogTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  CustomerOrderStrings.cancelDialogSubtitle(widget.orderId),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      CustomerOrderStrings.cancelReasonLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        CustomerOrderStrings.cancelReasonOptionalBadge,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((r) {
                    final isSelected = _selected == r;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selected = isSelected ? null : r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.error.withValues(alpha: 0.09)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.error
                                : AppColors.gray200,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.04,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              r,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_selected ==
                    CustomerOrderStrings.cancellationReasonOther) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _otherCtrl,
                    autofocus: true,
                    maxLines: 2,
                    maxLength: 200,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: CustomerOrderStrings.cancelReasonOtherHint,
                      hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.gray50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      counterStyle: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.gray300),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      CustomerOrderStrings.keepOrderButton,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDynamicButton(
                    borderRadius: 14,
                    accentColor: AppColors.error,
                    label: CustomerOrderStrings.cancelOrderButton,
                    onPressed: () => Navigator.pop(context, _finalReason),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
