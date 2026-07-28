import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/constants/food/business_constants/business_bank_account_strings.dart';
import 'package:food_app/constants/food/business_constants/business_order_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model_ui.dart';
import 'package:food_app/utils/currency_formatter.dart';
import 'package:food_app/widgets/images/network_image_widget.dart';
import 'package:intl/intl.dart';

class BusinessOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onAdvance;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;

  const BusinessOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onAdvance,
    this.onCancel,
    this.onBack,
  });

  Color get _accent {
    if (order.needsDecision) return AppColors.warning;
    if (order.bucket == OrderBucket.active) return AppColors.primary;
    if (order.status == 'cancelled') return AppColors.error;
    return AppColors.success;
  }

  Color get _borderColor {
    if (order.needsDecision) return AppColors.warning.withValues(alpha: 0.45);
    if (order.bucket == OrderBucket.active)
      return AppColors.primary.withValues(alpha: 0.30);
    if (order.status == 'cancelled')
      return AppColors.error.withValues(alpha: 0.25);
    return AppColors.success.withValues(alpha: 0.35);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status accent bar
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_accent, _accent.withValues(alpha: 0.6)],
                      ),
                    ),
                  ),

                  // Card body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 14),
                              _buildDivider(),
                              const SizedBox(height: 12),
                              _buildItems(),
                              if (order.notes?.isNotEmpty == true) ...[
                                const SizedBox(height: 10),
                                _buildNotes(),
                              ],
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),

                        // Footer — different for each bucket
                        _buildFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final customerName = order.user != null
        ? '${order.user!.firstName} ${order.user!.lastName}'.trim()
        : OrderStatusLabels.guest;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials(customerName),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _accent,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name + order ID + type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName.isEmpty ? OrderStatusLabels.guest : customerName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '#${CurrencyFormatter.localizeDigits(order.id)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _TypePill(isDelivery: order.isDelivery),
                  const SizedBox(width: 6),
                  _PaymentPill(paymentMethod: order.paymentMethod),
                ],
              ),
            ],
          ),
        ),

        // Total + elapsed
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.totalLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 11,
                  color: order.needsDecision
                      ? AppColors.warning
                      : AppColors.textHint,
                ),
                const SizedBox(width: 3),
                Text(
                  order.elapsedLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: order.needsDecision
                        ? AppColors.warning
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.divider,
                  AppColors.divider.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Items ─────────────────────────────────────────────────────────────────

  Widget _buildItems() {
    const maxVisible = 3;
    final items = order.orderItems;
    final visible = items.take(maxVisible).toList();
    final overflow = items.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item count pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                order.itemCountLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        ...visible.map((item) {
          final imageUrl = item.foodOffer.images.isNotEmpty
              ? item.foodOffer.images.first.url
              : null;
          final isWeight = item.weightKg != null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Food photo
                NetworkImageWidget(
                  imageUrl: imageUrl,
                  width: 48,
                  height: 48,
                  borderRadius: 10,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),

                // Qty / weight badge
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isWeight
                        ? AppColors.successLight
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    isWeight
                        ? CurrencyFormatter.formatWeight(item.weightKg!)
                        : '${CurrencyFormatter.localizeDigits('${item.quantity}')}×',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isWeight
                          ? AppColors.successDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Item name
                Expanded(
                  child: Text(
                    item.titleSnapshot.isNotEmpty
                        ? item.titleSnapshot
                        : item.foodOffer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Price
                Text(
                  CurrencyFormatter.format(
                    double.tryParse(item.totalPrice) ?? 0,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }),

        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 58),
            child: Text(
              BusinessOrderCardStrings.overflowHint(overflow),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            size: 14,
            color: AppColors.accentDark,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              order.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accentDark,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    // ── INCOMING: Accept / Reject ──────────────────────────────────────────
    if (order.needsDecision) {
      return _FooterContainer(
        color: AppColors.warningLight,
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: BusinessOrderCardStrings.acceptButton,
                icon: Icons.check_rounded,
                filled: true,
                color: AppColors.primary,
                onPressed: onAccept,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: BusinessOrderCardStrings.rejectButton,
                icon: Icons.close_rounded,
                filled: false,
                color: AppColors.error,
                onPressed: onReject,
              ),
            ),
          ],
        ),
      );
    }

    // ── ACTIVE: Advance + more ─────────────────────────────────────────────
    if (order.bucket == OrderBucket.active) {
      final nextLabel = switch (order.status) {
        'confirmed' => BusinessOrderCardStrings.advanceStartPreparing,
        'preparing' ||
        'ready_for_pickup' => BusinessOrderCardStrings.advanceMarkReady,
        'ready' =>
          order.isDelivery
              ? BusinessOrderCardStrings.advanceOutForDelivery
              : BusinessOrderCardStrings.advanceComplete,
        _ => BusinessOrderCardStrings.advanceFallback,
      };
      final nextIcon = switch (order.status) {
        'confirmed' => Icons.restaurant_rounded,
        'preparing' || 'ready_for_pickup' => Icons.done_rounded,
        'ready' =>
          order.isDelivery
              ? Icons.delivery_dining_rounded
              : Icons.check_circle_rounded,
        _ => Icons.arrow_forward_rounded,
      };

      return _FooterContainer(
        color: AppColors.primaryLight,
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: nextLabel,
                icon: nextIcon,
                filled: true,
                color: AppColors.primary,
                onPressed: onAdvance,
              ),
            ),
            if (onBack != null || onCancel != null)
              PopupMenuButton<String>(
                tooltip: BusinessOrderCardStrings.moreActionsTooltip,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (v) {
                  if (v == 'back') onBack?.call();
                  if (v == 'cancel') onCancel?.call();
                },
                itemBuilder: (_) => [
                  if (onBack != null)
                    PopupMenuItem(
                      value: 'back',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.undo_rounded),
                        title: Text(BusinessOrderCardStrings.moveBackAction),
                      ),
                    ),
                  if (onCancel != null)
                    PopupMenuItem(
                      value: 'cancel',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
                        ),
                        title: Text(
                          BusinessOrderCardStrings.cancelOrderAction,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    }

    // ── DONE: Status banner ────────────────────────────────────────────────
    final isDelivered =
        order.status == 'delivered' || order.status == 'completed';
    final color = isDelivered ? AppColors.successDark : AppColors.error;
    final bgColor = isDelivered ? AppColors.successLight : AppColors.errorLight;
    final icon = isDelivered
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    final rawTime = isDelivered ? order.completedAt : order.cancelledAt;
    final dt = rawTime != null ? DateTime.tryParse(rawTime)?.toLocal() : null;
    final timeStr = dt != null
        ? DateFormat('MMM d · HH:mm').format(dt)
        : order.elapsedLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          // Status icon in a soft circle
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),

          // Status + timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivered
                      ? BusinessOrderCardStrings.doneDelivered
                      : BusinessOrderCardStrings.doneCancelled,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // "Details" chip button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    BusinessOrderCardStrings.detailsButton,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _FooterContainer extends StatelessWidget {
  const _FooterContainer({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
      decoration: BoxDecoration(
        color: color,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomDynamicButton(
      label: label,
      onPressed: onPressed,
      variant: filled
          ? CustomButtonVariant.filled
          : CustomButtonVariant.outlined,
      accentColor: color,
      icon: icon,
      borderRadius: 11,
    );
  }
}

class _PaymentPill extends StatelessWidget {
  final String paymentMethod;
  const _PaymentPill({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    final isCash = paymentMethod == 'cash';
    final color = isCash ? AppColors.warningDark : AppColors.textSecondary;
    final bg = isCash ? AppColors.warningLight : AppColors.gray100;
    final icon = isCash ? Icons.payments_outlined : Icons.credit_card_rounded;
    final label = isCash
        ? PaymentMethodStrings.cash
        : PaymentMethodStrings.card;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final bool isDelivery;
  const _TypePill({required this.isDelivery});

  @override
  Widget build(BuildContext context) {
    final color = isDelivery ? AppColors.info : AppColors.primary;
    final bg = isDelivery ? AppColors.infoLight : AppColors.primaryLight;
    final icon = isDelivery
        ? Icons.delivery_dining_rounded
        : Icons.storefront_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            isDelivery
                ? BusinessOrderCardStrings.typeDelivery
                : BusinessOrderCardStrings.typePickup,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
