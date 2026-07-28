// Generic customer order-detail screen — collapsible hero (order photos, or
// a gradient header when none are available) over order number/status/date,
// followed by an ordered list of content sections. Reusable across markets
// the same way OrderListScreen<T> is: a market wiring layer (e.g. Food's
// OrderDetailScreen) extracts primitive values from its own order model into
// an [OrderDetailConfig] and supplies [OrderDetailConfig.sections] fully
// built — status tracker, location, items, payment summary, actions, help —
// since those differ enough per market (ratings/edit/reorder for Food,
// nothing yet for Cosmetic) that forcing one shape on all of them would cost
// more than it saves. What's shared is the collapsing photo/gradient shell,
// which is genuinely identical work every market needs.
//
// This file never imports a market model, market controller, or a market's
// translation keys.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/profile_and_orders/profile/utils/status_helper.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/helper_methods.dart';
import 'package:get/get.dart';

/// Maps a raw order-status string to its localized display label. Reuses
/// the same `orderStatus_*` translation keys `OrderModelUi.statusLabel`
/// already does — wording is market-neutral ("New", "Confirmed",
/// "Preparing", "Ready", "Delivered", "Cancelled"), so both markets share it
/// directly instead of each keeping their own copy of this switch.
String orderStatusLabel(String status) => switch (status) {
  'pending' => 'orderStatus_new'.tr,
  'confirmed' => 'orderStatus_confirmed'.tr,
  'preparing' => 'orderStatus_preparing'.tr,
  'ready' || 'ready_for_pickup' => 'orderStatus_ready'.tr,
  'delivered' || 'completed' => 'orderStatus_delivered'.tr,
  'cancelled' => 'orderStatus_cancelled'.tr,
  _ => status,
};

/// True while an order is still awaiting the business partner's decision —
/// the only state in which a customer may still edit or cancel it. Single
/// source of truth shared by both markets so "can this order still be
/// edited/cancelled" is never checked with a one-off string comparison.
bool isPendingOrderStatus(String status) => status.toLowerCase() == 'pending';

/// True once an order has reached a state it can no longer transition out
/// of (delivered/completed/cancelled) — shared by both markets' order lists
/// and detail screens.
bool isTerminalOrderStatus(String status) =>
    const {'completed', 'delivered', 'cancelled'}.contains(status.toLowerCase());

/// Everything [OrderDetailScreen] needs to render one market's order detail.
/// A market wires this up once (see Food's OrderDetailScreen) by extracting
/// values from its own order model.
class OrderDetailConfig {
  /// Already-formatted "Order #123" (or equivalent) label.
  final String orderNumberLabel;

  /// Raw status string (e.g. 'pending', 'cancelled') — drives the status
  /// chip's color/label via [StatusHelper.getStatusColor]/[orderStatusLabel].
  final String status;

  /// Already-formatted order date/time.
  final String formattedDate;

  /// Shown next to the clock icon in the header (e.g. "Delivery"/"Pickup").
  final String logisticsLabel;

  /// Photo hero images — empty shows the gradient header instead.
  final List<String> imageUrls;

  /// True while a background refresh of this order is in flight (thin
  /// progress bar under the app bar).
  final RxBool isRefreshing;

  /// Content sections in display order — each one fully built by the
  /// market wiring layer (status tracker, location, items, payment summary,
  /// actions, help, ...).
  final List<Widget> sections;

  const OrderDetailConfig({
    required this.orderNumberLabel,
    required this.status,
    required this.formattedDate,
    required this.logisticsLabel,
    required this.imageUrls,
    required this.isRefreshing,
    required this.sections,
  });
}

class OrderDetailScreen extends StatefulWidget {
  final OrderDetailConfig config;

  const OrderDetailScreen({super.key, required this.config});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _scrollCtrl = ScrollController();
  static const double _expandedHeight = 220;

  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed = _scrollCtrl.offset > (_expandedHeight - kToolbarHeight - 4);
    if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final lightIcons = !_isCollapsed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightIcons ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              pinned: true,
              backgroundColor: _isCollapsed ? AppColors.white : Colors.transparent,
              foregroundColor: lightIcons ? Colors.white : AppColors.black,
              elevation: _isCollapsed ? 0.5 : 0,
              shadowColor: Colors.black12,
              centerTitle: true,
              title: Text(
                config.orderNumberLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: lightIcons ? Colors.white : AppColors.black,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: Obx(
                  () => config.isRefreshing.value
                      ? const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: AppColors.primary,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: config.imageUrls.isNotEmpty
                    ? _OrderImagesHero(imageUrls: config.imageUrls)
                    : _GradientHeader(config: config),
              ),
            ),
            SliverToBoxAdapter(
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // When images fill the header, show the order-info card
                    // in the scroll body. When the gradient header is used,
                    // it already shows that info so we skip the card.
                    if (config.imageUrls.isNotEmpty) _OrderInfoCard(config: config),
                    ...config.sections,
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient header (shown when no order photos are available) ──────────────

class _GradientHeader extends StatelessWidget {
  final OrderDetailConfig config;
  const _GradientHeader({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      config.orderNumberLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: config.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    config.formattedDate,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.delivery_dining_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    config.logisticsLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status chip (white-glass style for gradient bg) ──────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        HelperMethods.capitalizeFirst(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Order-info card (shown below photo hero when images are present) ────────

class _OrderInfoCard extends StatelessWidget {
  final OrderDetailConfig config;
  const _OrderInfoCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusHelper.getStatusColor(config.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  config.orderNumberLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  orderStatusLabel(config.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                config.formattedDate,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.delivery_dining_rounded,
                size: 15,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                config.logisticsLabel,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Photo hero (shown when order photos are available) ──────────────────────

class _OrderImagesHero extends StatefulWidget {
  final List<String> imageUrls;
  const _OrderImagesHero({required this.imageUrls});

  @override
  State<_OrderImagesHero> createState() => _OrderImagesHeroState();
}

class _OrderImagesHeroState extends State<_OrderImagesHero> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: widget.imageUrls.length,
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: widget.imageUrls[i],
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.primaryLight),
            errorWidget: (_, _, _) => Container(
              color: AppColors.primaryLight,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textSecondary,
                size: 48,
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x80000000)],
                ),
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) {
                final active = _page == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
