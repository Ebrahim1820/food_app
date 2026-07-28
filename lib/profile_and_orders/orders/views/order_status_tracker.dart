import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:design_system/design_system.dart';

/// Horizontal "track your order" stepper — Placed → Confirmed → Ready →
/// Completed — with a distinct red banner in place of the stepper when the
/// order was cancelled (a broken/partial stepper doesn't read well, since
/// cancellation can happen from any prior state).
///
/// [compact] renders the same stepper at list-card scale: smaller circles,
/// no step labels, no card chrome (margin/padding/shadow) — used on
/// [OrderSummaryCard] so both places share one canonical implementation of
/// "what stage is this order at" instead of two different-looking trackers.
/// A cancelled order in compact mode renders nothing (the card's status
/// badge already says "Cancelled"; a full banner is too heavy for a list row).
class OrderStatusTracker extends StatelessWidget {
  const OrderStatusTracker({
    super.key,
    required this.status,
    this.cancellationReason,
    this.compact = false,
  });

  /// Raw order-status string (e.g. 'pending', 'cancelled') — same value
  /// both `OrderModel.status` and `ProductOrderModel.status` carry, so
  /// either market can drive this tracker directly.
  final String status;
  final String? cancellationReason;
  final bool compact;

  static const _steps = [
    OrderStatusEnums.pending,
    OrderStatusEnums.confirmed,
    OrderStatusEnums.readyForPickup,
    OrderStatusEnums.completed,
  ];

  static const _icons = [
    Icons.receipt_long_rounded,
    Icons.storefront_rounded,
    Icons.shopping_bag_rounded,
    Icons.check_circle_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final currentStatus = OrderStatusEnums.fromValue(status);

    if (currentStatus == OrderStatusEnums.cancelled) {
      return compact
          ? const SizedBox.shrink()
          : _CancelledBanner(reason: cancellationReason);
    }

    final currentIndex = _steps.indexOf(currentStatus);

    final circleSize = compact ? 18.0 : 30.0;
    final lineTop = circleSize / 2 - 1.5;
    final lineHeight = compact ? 2.0 : 3.0;
    final stepper = SizedBox(
      height: compact ? circleSize : 64,
      child: Stack(
        children: [
          Positioned(
            top: lineTop,
            left: circleSize / 2,
            right: circleSize / 2,
            child: Row(
              children: List.generate(_steps.length - 1, (i) {
                final done = i < currentIndex;
                return Expanded(
                  child: Container(
                    height: lineHeight,
                    color: done ? AppColors.successDark : AppColors.gray200,
                  ),
                );
              }),
            ),
          ),
          Row(
            children: List.generate(_steps.length, (i) {
              final state = i < currentIndex
                  ? _StepState.done
                  : i == currentIndex
                  ? _StepState.active
                  : _StepState.upcoming;
              final circle = _StepCircle(
                icon: _icons[i],
                state: state,
                size: circleSize,
              );
              return Expanded(
                child: compact
                    ? Center(child: circle)
                    : Column(
                        children: [
                          circle,
                          const SizedBox(height: 6),
                          Text(
                            _labelFor(i),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: state == _StepState.upcoming
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: state == _StepState.upcoming
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
              );
            }),
          ),
        ],
      ),
    );

    if (compact) return stepper;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: stepper,
    );
  }

  static String _labelFor(int i) => switch (i) {
    0 => CustomerOrderStrings.trackerPlaced,
    1 => CustomerOrderStrings.trackerConfirmed,
    2 => CustomerOrderStrings.trackerReady,
    _ => CustomerOrderStrings.trackerCompleted,
  };
}

enum _StepState { done, active, upcoming }

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.icon,
    required this.state,
    required this.size,
  });

  final IconData icon;
  final _StepState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      _StepState.done => AppColors.successDark,
      _StepState.active => AppColors.primary,
      _StepState.upcoming => AppColors.gray200,
    };
    final iconColor = state == _StepState.upcoming
        ? AppColors.gray500
        : AppColors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: state == _StepState.active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        state == _StepState.done ? Icons.check_rounded : icon,
        size: size * 0.53,
        color: iconColor,
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: AppColors.errorDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CustomerOrderStrings.cancelledBannerTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorDark,
                  ),
                ),
                if (reason != null && reason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${CustomerOrderStrings.cancellationReasonLabel}: ${reason!.trim()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.errorDark.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
