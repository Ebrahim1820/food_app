import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:food_app/controllers/admin_controller.dart';
import 'package:auth/auth.dart';
import 'package:food_app/models/admin_stats_model.dart';
import 'package:food_app/screens/admin/admin_broadcast_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

class AdminOverviewTab extends StatelessWidget {
  final AdminController ctrl;
  final VoidCallback onGoToPartners;
  final VoidCallback onGoToCustomers;

  const AdminOverviewTab({
    super.key,
    required this.ctrl,
    required this.onGoToPartners,
    required this.onGoToCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: ctrl.fetchAll,
      child: Obx(() {
        final loading =
            ctrl.isLoading.value && ctrl.stats.value == AdminStats.empty;
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _GreetingHeader(),
            const SizedBox(height: 24),
            _sectionLabel('Platform Metrics'),
            const SizedBox(height: 14),
            _MetricsGrid(stats: ctrl.stats.value, ctrl: ctrl),
            const SizedBox(height: 28),
            _sectionLabel('Quick Access'),
            const SizedBox(height: 14),
            _QuickAccessRow(
              onGoToPartners: onGoToPartners,
              onGoToCustomers: onGoToCustomers,
              ctrl: ctrl,
            ),
            const SizedBox(height: 28),
            _sectionLabel('Actions'),
            const SizedBox(height: 14),
            const _BroadcastActionCard(),
            const SizedBox(height: 28),
            _sectionLabel('Order Breakdown'),
            const SizedBox(height: 14),
            _OrderBreakdownCard(stats: ctrl.stats.value),
            const SizedBox(height: 28),
            _sectionLabel('Offer Distribution'),
            const SizedBox(height: 14),
            _OfferDistributionCard(ctrl: ctrl),
          ],
        );
      }),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.gray500,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2B4A), Color(0xFF243759)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2B4A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    '$greeting, ${auth.firstName} 👋',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formattedDate(now),
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month]} ${d.day}';
  }
}

// ── Metrics Grid ──────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final AdminStats stats;
  final AdminController ctrl;
  const _MetricsGrid({required this.stats, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1 — distribution cards with mini donut
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _PartnerDistCard(ctrl: ctrl)),
              const SizedBox(width: 12),
              Expanded(child: _CustomerDistCard(ctrl: ctrl)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Row 2 — compact stat cards
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                metric: _Metric(
                  'Offers',
                  stats.totalOffers,
                  Icons.lunch_dining_rounded,
                  AppColors.accent,
                  AppColors.accentLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                metric: _Metric(
                  'Orders',
                  stats.totalOrders,
                  Icons.receipt_long_rounded,
                  AppColors.purple,
                  AppColors.purpleLight,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: metric.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, color: metric.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${metric.count}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  height: 1.1,
                ),
              ),
              Text(
                metric.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bg;
  const _Metric(this.label, this.count, this.icon, this.color, this.bg);
}

// ── Partner Distribution Card ─────────────────────────────────────────────────

class _PartnerDistCard extends StatelessWidget {
  final AdminController ctrl;
  const _PartnerDistCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final partners = ctrl.partners;
      int approved = 0, pending = 0, rejected = 0;
      for (final p in partners) {
        final s = p.kycStatus.toLowerCase();
        if (s == 'approved' || s == 'verified') {
          approved++;
        } else if (s == 'pending' || s == 'in_review' || s == 'under_review') {
          pending++;
        } else if (s.isNotEmpty) {
          rejected++;
        }
      }
      final total = partners.length;
      final segments = [
        _Segment('Approved', approved, AppColors.successDark),
        _Segment('Pending', pending, AppColors.warning),
        _Segment('Rejected', rejected, AppColors.error),
      ];
      return _DistCard(
        icon: Icons.storefront_rounded,
        iconColor: const Color(0xFF1D4ED8),
        iconBg: const Color(0xFFDBEAFE),
        title: 'Partners',
        total: total,
        segments: segments,
      );
    });
  }
}

// ── Customer Distribution Card ────────────────────────────────────────────────

class _CustomerDistCard extends StatelessWidget {
  final AdminController ctrl;
  const _CustomerDistCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final customers = ctrl.customers;
      int customer = 0, partner = 0, admin = 0;
      for (final u in customers) {
        final roles = u.roles.map((r) => r.toUpperCase());
        if (roles.any((r) => r.contains('ADMIN'))) {
          admin++;
        } else if (roles.any((r) => r.contains('BUSINESS_PARTNER'))) {
          partner++;
        } else {
          customer++;
        }
      }
      final total = customers.length;
      final segments = [
        _Segment('Customer', customer, AppColors.primary),
        _Segment('Partner', partner, const Color(0xFF1D4ED8)),
        _Segment('Admin', admin, AppColors.purple),
      ];
      return _DistCard(
        icon: Icons.people_alt_rounded,
        iconColor: AppColors.primary,
        iconBg: AppColors.primaryLight,
        title: 'Customers',
        total: total,
        segments: segments,
      );
    });
  }
}

// ── Shared Distribution Card Layout ──────────────────────────────────────────

class _DistCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final int total;
  final List<_Segment> segments;
  const _DistCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.total,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini donut + legend
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: total == 0
                    ? CustomPaint(
                        painter: _DonutPainter(
                          segments: [_Segment('', 1, AppColors.gray100)],
                          total: 1,
                        ),
                      )
                    : CustomPaint(
                        painter: _DonutPainter(
                          segments: segments,
                          total: total,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: segments.map((s) {
                    final pct = total > 0 ? (s.count / total * 100).round() : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              s.label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.gray500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Access ──────────────────────────────────────────────────────────────

class _QuickAccessRow extends StatelessWidget {
  final VoidCallback onGoToPartners;
  final VoidCallback onGoToCustomers;
  final AdminController ctrl;

  const _QuickAccessRow({
    required this.onGoToPartners,
    required this.onGoToCustomers,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _QuickCard(
              icon: Icons.storefront_rounded,
              label: 'View Partners',
              value: '${ctrl.partners.length}',
              color: const Color(0xFF1D4ED8),
              bg: const Color(0xFFDBEAFE),
              onTap: onGoToPartners,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickCard(
              icon: Icons.people_alt_rounded,
              label: 'View Customers',
              value: '${ctrl.customers.length}',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              onTap: onGoToCustomers,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Broadcast action ──────────────────────────────────────────────────────

class _BroadcastActionCard extends StatelessWidget {
  const _BroadcastActionCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const AdminBroadcastScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2B4A), Color(0xFF243759)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1A2B4A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Broadcast',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Push a notification to every customer right now',
                    style: TextStyle(fontSize: 11.5, color: Color(0xB3FFFFFF)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gray300,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Breakdown ───────────────────────────────────────────────────────────

class _OrderBreakdownCard extends StatelessWidget {
  final AdminStats stats;
  const _OrderBreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final completed =
        stats.totalOrders -
        stats.pendingOrders -
        stats.activeOrders -
        stats.cancelledOrders;

    final rows = [
      _BreakdownRow('Pending', stats.pendingOrders, AppColors.warning),
      _BreakdownRow('Active', stats.activeOrders, AppColors.infoDark),
      _BreakdownRow(
        'Completed',
        completed.clamp(0, 999999),
        AppColors.successDark,
      ),
      _BreakdownRow('Cancelled', stats.cancelledOrders, AppColors.error),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BreakdownRowWidget(row: r, total: stats.totalOrders),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BreakdownRow {
  final String label;
  final int count;
  final Color color;
  const _BreakdownRow(this.label, this.count, this.color);
}

class _BreakdownRowWidget extends StatelessWidget {
  final _BreakdownRow row;
  final int total;
  const _BreakdownRowWidget({required this.row, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (row.count / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: row.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                row.label,
                style: const TextStyle(fontSize: 13, color: AppColors.gray600),
              ),
            ),
            Text(
              '${row.count}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.gray100,
            valueColor: AlwaysStoppedAnimation<Color>(row.color),
          ),
        ),
      ],
    );
  }
}

// ── Offer Distribution Card ───────────────────────────────────────────────────

class _OfferDistributionCard extends StatelessWidget {
  final AdminController ctrl;
  const _OfferDistributionCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final offers = ctrl.offers;
      final now = DateTime.now();

      int active = 0;
      int upcoming = 0;
      int soldOut = 0;
      int expired = 0;

      for (final o in offers) {
        if (o.endTime.isBefore(now)) {
          expired++;
        } else if (o.startTime.isAfter(now)) {
          upcoming++;
        } else if (o.quantityAvailable == 0) {
          soldOut++;
        } else {
          active++;
        }
      }

      final total = offers.length;

      final segments = [
        _Segment('Active', active, AppColors.successDark),
        _Segment('Upcoming', upcoming, AppColors.infoDark),
        _Segment('Sold Out', soldOut, AppColors.accent),
        _Segment('Expired', expired, AppColors.gray300),
      ];

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: total == 0
            ? const SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'No offers yet',
                    style: TextStyle(color: AppColors.gray400, fontSize: 13),
                  ),
                ),
              )
            : Row(
                children: [
                  // ── Donut chart ─────────────────────────────────────────
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: _DonutPainter(segments: segments, total: total),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                                height: 1.1,
                              ),
                            ),
                            const Text(
                              'offers',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // ── Legend ──────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: segments
                          .map((s) => _LegendRow(segment: s, total: total))
                          .toList(),
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

// ── Legend Row ────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final _Segment segment;
  final int total;
  const _LegendRow({required this.segment, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (segment.count / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: segment.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              segment.label,
              style: const TextStyle(fontSize: 13, color: AppColors.gray600),
            ),
          ),
          Text(
            '${segment.count}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: Text(
              '$pct%',
              style: const TextStyle(fontSize: 11, color: AppColors.gray400),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donut Painter ─────────────────────────────────────────────────────────────

class _Segment {
  final String label;
  final int count;
  final Color color;
  const _Segment(this.label, this.count, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  final int total;
  const _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy);
    final innerR = outerR * 0.58;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: outerR);

    const gapAngle = 0.04; // radians gap between slices
    double startAngle = -math.pi / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final seg in segments) {
      if (seg.count == 0) continue;
      final sweep = (seg.count / total) * (2 * math.pi) - gapAngle;

      paint.color = seg.color;
      canvas.drawArc(rect, startAngle, sweep, true, paint);

      startAngle += sweep + gapAngle;
    }

    // Punch out the centre hole to create the donut effect
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), innerR, paint);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments || old.total != total;
}
