import 'package:flutter/material.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_order_controller.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model_ui.dart';
import 'package:food_app/constants/food/business_constants/business_order_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/currency_formatter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BusinessOrderDetailScreen extends StatefulWidget {
  const BusinessOrderDetailScreen({super.key, required this.order});

  /// The order as it exists in the list — used for immediate display.
  /// A fresh fetch runs on init to get the full embedded data (orderItems, etc.).
  final OrderModel order;

  @override
  State<BusinessOrderDetailScreen> createState() =>
      _BusinessOrderDetailScreenState();
}

class _BusinessOrderDetailScreenState extends State<BusinessOrderDetailScreen> {
  late final BusinessOrderController _ctrl;

  static String _fmt(String raw) =>
      CurrencyFormatter.format(double.tryParse(raw) ?? 0);

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<BusinessOrderController>();
    // Fetch the full order (with embedded orderItems + complete user) in the
    // background. The screen immediately shows whatever was in the list cache.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ctrl.fetchOrderById(widget.order.id),
    );
  }

  @override
  void dispose() {
    // Clear selectedOrder so stale data doesn't bleed into the next detail screen.
    if (_ctrl.selectedOrder.value?.id == widget.order.id) {
      _ctrl.selectedOrder.value = null;
    }
    super.dispose();
  }

  OrderModel get _order {
    final fetched = _ctrl.selectedOrder.value;
    return fetched?.id == widget.order.id ? fetched! : widget.order;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final order = _order;
      final isRefreshing =
          _ctrl.isDetailLoading.value && _ctrl.selectedOrder.value == null;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context, order),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  MediaQuery.paddingOf(context).bottom + 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (isRefreshing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(
                          backgroundColor: AppColors.primaryLight,
                          color: AppColors.primary,
                          minHeight: 2,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    _buildCustomerCard(order),
                    const SizedBox(height: 16),
                    _buildItemsCard(order),
                    if (order.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _buildNotesCard(order),
                    ],
                    const SizedBox(height: 16),
                    _buildPickupDeliveryCard(order),
                    const SizedBox(height: 16),
                    _buildPriceCard(order),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, order),
      );
    });
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, OrderModel order) {
    final dt = DateTime.tryParse(order.createdAt)?.toLocal();
    final dateStr = dt != null
        ? DateFormat("MMM d, y '·' HH:mm").format(dt)
        : '';

    return SliverAppBar(
      expandedHeight: 165,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: AppColors.white),
      title: Text(
        BusinessOrderDetailStrings.appBarTitle(
          CurrencyFormatter.localizeDigits(order.id),
        ),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.headerGradientStart,
                AppColors.headerGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        BusinessOrderDetailStrings.appBarTitle(
                          CurrencyFormatter.localizeDigits(order.id),
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        order.isDelivery
                            ? Icons.delivery_dining_rounded
                            : Icons.storefront_rounded,
                        size: 13,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.isDelivery
                            ? BusinessOrderDetailStrings.typeDelivery
                            : BusinessOrderDetailStrings.typePickup,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Customer card ─────────────────────────────────────────────────────────

  Widget _buildCustomerCard(OrderModel order) {
    final u = order.user;
    final firstName = u?.firstName ?? '';
    final lastName = u?.lastName ?? '';
    final initials = _initials(firstName, lastName);
    final fullName = '$firstName $lastName'.trim();
    final phone = u?.phone ?? '';
    final email = u?.email ?? '';

    return _SectionCard(
      icon: Icons.person_rounded,
      title: BusinessOrderDetailStrings.sectionCustomer,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? OrderStatusLabels.guest : fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _IconRow(icon: Icons.email_outlined, label: email),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _IconRow(
                    icon: Icons.phone_outlined,
                    label: CurrencyFormatter.localizeDigits(phone),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Items card ────────────────────────────────────────────────────────────

  Widget _buildItemsCard(OrderModel order) {
    final items = order.orderItems;

    return _SectionCard(
      icon: Icons.shopping_bag_outlined,
      title: order.itemCountLabel,
      child: items.isEmpty
          ? const _EmptyItemsHint()
          : Column(
              children: [
                // Column headers
                Row(
                  children: [
                    SizedBox(width: 34),
                    Expanded(
                      child: Text(
                        BusinessOrderDetailStrings.itemColumnItem,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    Text(
                      BusinessOrderDetailStrings.itemColumnUnit,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: Text(
                        BusinessOrderDetailStrings.itemColumnTotal,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${CurrencyFormatter.localizeDigits('${item.quantity}')}×',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.foodOffer.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(item.unitPrice),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            _fmt(item.totalPrice),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Notes card ────────────────────────────────────────────────────────────

  Widget _buildNotesCard(OrderModel order) {
    return _SectionCard(
      icon: Icons.sticky_note_2_outlined,
      title: BusinessOrderDetailStrings.sectionCustomerNotes,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Text(
          order.notes!,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.accentDark,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Pickup / Delivery card ─────────────────────────────────────────────────

  Widget _buildPickupDeliveryCard(OrderModel order) {
    // Resolve best available time string:
    // prefer the backend-formatted label; fall back to parsing the raw ISO time.
    String? timeStr;
    if (order.estimatedDeliveryLabel?.isNotEmpty == true) {
      timeStr = order.estimatedDeliveryLabel;
    } else if (order.estimatedDeliveryTime?.isNotEmpty == true) {
      final dt = DateTime.tryParse(order.estimatedDeliveryTime!)?.toLocal();
      if (dt != null) {
        timeStr = DateFormat("MMM d '·' HH:mm").format(dt);
      }
    }

    final hasAddress = order.deliveryAddress?.isNotEmpty == true;

    if (order.isDelivery) {
      return _SectionCard(
        icon: Icons.delivery_dining_rounded,
        title: BusinessOrderDetailStrings.sectionDelivery,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAddress)
              _IconRow(
                icon: Icons.location_on_outlined,
                label: order.deliveryAddress!,
              ),
            if (timeStr != null) ...[
              if (hasAddress) const SizedBox(height: 12),
              _TimeChip(
                label: BusinessOrderDetailStrings.estDelivery,
                time: timeStr,
              ),
            ],
            if (!hasAddress && timeStr == null)
              _IconRow(
                icon: Icons.info_outline_rounded,
                label: BusinessOrderDetailStrings.noDeliveryInfo,
              ),
          ],
        ),
      );
    }

    // Pickup
    return _SectionCard(
      icon: Icons.storefront_rounded,
      title: BusinessOrderDetailStrings.sectionPickup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconRow(
            icon: Icons.storefront_outlined,
            label: order.businessPartner.businessName,
          ),
          if (hasAddress) ...[
            const SizedBox(height: 10),
            _IconRow(
              icon: Icons.location_on_outlined,
              label: order.deliveryAddress!,
            ),
          ],
          if (timeStr != null) ...[
            const SizedBox(height: 12),
            _TimeChip(label: BusinessOrderDetailStrings.readyBy, time: timeStr),
          ],
        ],
      ),
    );
  }

  // ── Price card ────────────────────────────────────────────────────────────

  Widget _buildPriceCard(OrderModel order) {
    return _SectionCard(
      icon: Icons.receipt_long_rounded,
      title: BusinessOrderDetailStrings.sectionPriceSummary,
      child: Column(
        children: [
          _PriceRow(
            label: BusinessOrderDetailStrings.subtotalLabel,
            value: _fmt(order.subtotal),
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: BusinessOrderDetailStrings.deliveryFeeLabel,
            value: order.deliveryFeeValue > 0
                ? _fmt(order.deliveryFee)
                : BusinessOrderDetailStrings.deliveryFeeFree,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Text(
                BusinessOrderDetailStrings.totalLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                order.totalLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ─────────────────────────────────────────────────────

  Widget? _buildBottomBar(BuildContext context, OrderModel order) {
    if (order.needsDecision) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: CustomDynamicButton(
                  label: BusinessOrderDetailStrings.acceptButton,
                  onPressed: () {
                    _ctrl.accept(order);
                    Get.back();
                  },
                  icon: Icons.check_rounded,
                  accentColor: AppColors.primary,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomDynamicButton(
                  label: BusinessOrderDetailStrings.rejectButton,
                  onPressed: () {
                    _ctrl.reject(order);
                    Get.back();
                  },
                  variant: CustomButtonVariant.outlined,
                  accentColor: AppColors.error,
                  icon: Icons.close_rounded,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (order.bucket == OrderBucket.active) {
      final nextStatus =
          OrderStatusEnums.fromValue(order.status).next?.value ?? order.status;
      final nextLabel = switch (order.status) {
        'confirmed' => BusinessOrderDetailStrings.advanceStartPreparing,
        'preparing' => BusinessOrderDetailStrings.advanceMarkReady,
        'ready' =>
          order.isDelivery
              ? BusinessOrderDetailStrings.advanceOutForDelivery
              : BusinessOrderDetailStrings.advanceMarkComplete,
        _ => BusinessOrderDetailStrings.advanceFallback,
      };
      final nextIcon = switch (order.status) {
        'confirmed' => Icons.restaurant_rounded,
        'preparing' => Icons.done_rounded,
        'ready' =>
          order.isDelivery
              ? Icons.delivery_dining_rounded
              : Icons.check_circle_rounded,
        _ => Icons.arrow_forward_rounded,
      };

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: CustomDynamicButton(
                  label: nextLabel,
                  onPressed: () {
                    _ctrl.updateStatus(order, nextStatus);
                    Get.back();
                  },
                  icon: nextIcon,
                  accentColor: AppColors.primary,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 8),
              CustomDynamicButton(
                label: BusinessOrderDetailStrings.cancelButton,
                onPressed: () {
                  _ctrl.cancel(order);
                  Get.back();
                },
                variant: CustomButtonVariant.outlined,
                accentColor: AppColors.error,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  static String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  _IconRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: AppColors.textHint),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyItemsHint extends StatelessWidget {
  const _EmptyItemsHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.sync_rounded, size: 15, color: AppColors.textHint),
          SizedBox(width: 8),
          Text(
            BusinessOrderDetailStrings.itemsLoading,
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.time});
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _bg => switch (status) {
    'pending' => AppColors.warningLight,
    'confirmed' || 'preparing' || 'ready' => AppColors.successLight,
    'delivered' => AppColors.successLight,
    'cancelled' => AppColors.errorLight,
    _ => AppColors.gray100,
  };

  Color get _fg => switch (status) {
    'pending' => AppColors.warningDark,
    'confirmed' || 'preparing' || 'ready' => AppColors.successDark,
    'delivered' => AppColors.successDark,
    'cancelled' => AppColors.errorDark,
    _ => AppColors.gray600,
  };

  String get _label => switch (status) {
    'pending' => OrderStatusLabels.newOrder,
    'confirmed' => OrderStatusLabels.confirmed,
    'preparing' => OrderStatusLabels.preparing,
    'ready' => OrderStatusLabels.ready,
    'delivered' => OrderStatusLabels.delivered,
    'cancelled' => OrderStatusLabels.cancelled,
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _fg),
      ),
    );
  }
}
