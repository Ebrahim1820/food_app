import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// A full-width hero card for the business dashboard.
///
/// Shows: business name · open/closed status · greeting · date ·
/// today's earnings · order count · rating · pending payout.
///
/// All values are passed as constructor params so the card is
/// completely reusable — drop it in any screen and wire up the data.
///
/// Usage:
/// ```dart
/// Obx(() => BusinessSummaryCard(
///   businessName: ctrl.partnerName,
///   isOpen: ctrl.partner.value?.isActive ?? false,
///   todayEarnings: '€ 241',
///   ordersToday: '12',
///   rating: ctrl.partner.value?.rating ?? 0,
///   pendingPayout: '€ 280',
/// ))
/// ```
class BusinessSummaryCard extends StatelessWidget {
  final String businessName;
  final bool isOpen;
  final String todayEarnings;
  final String ordersToday;
  final double rating;
  final String pendingPayout;

  /// Called when the rating stat is tapped — omit to leave it non-interactive.
  final VoidCallback? onRatingTap;

  const BusinessSummaryCard({
    super.key,
    required this.businessName,
    required this.isOpen,
    this.todayEarnings = '—',
    this.ordersToday = '—',
    this.rating = 0.0,
    this.pendingPayout = '—',
    this.onRatingTap,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'greeting_morning'.tr;
    if (h < 17) return 'greeting_afternoon'.tr;
    return 'greeting_evening'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2044), AppColors.successDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // — decorative background circles —
          Positioned(right: -44, top: -44, child: _circle(180, 0.07)),
          Positioned(right: 56, top: -18, child: _circle(80, 0.045)),
          Positioned(left: -28, bottom: -28, child: _circle(110, 0.055)),

          // — main content —
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting + status pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _greeting,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        _StatusPill(isOpen: isOpen),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Business name
                    Text(
                      businessName.isEmpty ? '—' : businessName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Date row
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // — frosted stats strip —
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.11),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _StatItem(
                        icon: Icons.payments_outlined,
                        value: todayEarnings,
                        label: 'bizSummary_todaysNet'.tr,
                      ),
                      _divider(),
                      _StatItem(
                        icon: Icons.receipt_long_outlined,
                        value: ordersToday,
                        label: 'bizSummary_orders'.tr,
                      ),
                      _divider(),
                      _StatItem(
                        icon: Icons.star_rounded,
                        value: rating > 0
                            ? CurrencyFormatter.localizeDigits(
                                rating.toStringAsFixed(1),
                              )
                            : '—',
                        label: 'bizSummary_rating'.tr,
                        iconColor: const Color(0xFFFFD060),
                        onTap: onRatingTap,
                      ),
                      _divider(),
                      _StatItem(
                        icon: Icons.schedule_outlined,
                        value: pendingPayout,
                        label: 'bizSummary_pending'.tr,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );

  Widget _divider() =>
      Container(width: 0.5, color: Colors.white.withValues(alpha: 0.20));
}

// ---------------------------------------------------------------------------
// Open / Closed pill
// ---------------------------------------------------------------------------
class _StatusPill extends StatelessWidget {
  final bool isOpen;
  const _StatusPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.success : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'partner_open'.tr : 'partner_closed'.tr,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat item (icon + value + label)
// ---------------------------------------------------------------------------
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  /// Optional tap handler — when set, the whole stat becomes tappable
  /// (e.g. the rating stat opens the reviews screen).
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: iconColor ?? Colors.white.withValues(alpha: 0.80),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.60),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: content,
            ),
    );
  }
}
