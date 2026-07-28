import 'package:flutter/material.dart';
import 'package:admin_platform/admin_platform.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminOrdersTab extends StatelessWidget {
  final AdminController ctrl;
  const AdminOrdersTab({super.key, required this.ctrl});

  static const _filters = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('active', 'Active'),
    ('done', 'Done'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchAndFilter(ctrl: ctrl),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ctrl.refreshOrders,
            child: Obx(() {
              final list = ctrl.filteredOrders;
              if (ctrl.isLoading.value && list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'No orders found.',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: list.length,
                itemBuilder: (_, i) => _AdminOrderCard(order: list[i]),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SearchAndFilter extends StatefulWidget {
  final AdminController ctrl;
  const _SearchAndFilter({required this.ctrl});

  @override
  State<_SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<_SearchAndFilter> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => widget.ctrl.ordersSearch.value = v,
            decoration: InputDecoration(
              hintText: 'Search by ID, customer or partner…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.ctrl.ordersSearch.value = '';
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onTap: () => setState(() {}),
          ),
        ),
        Obx(() {
          final current = widget.ctrl.ordersStatusFilter.value;
          return SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: AdminOrdersTab._filters.map((
                (String key, String label) pair,
              ) {
                final selected = current == pair.$1;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: FilterChip(
                    label: Text(pair.$2),
                    selected: selected,
                    onSelected: (_) =>
                        widget.ctrl.ordersStatusFilter.value = pair.$1,
                    selectedColor: AppColors.navy.withValues(alpha: 0.12),
                    checkmarkColor: AppColors.navy,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.navy : AppColors.gray600,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.navy : AppColors.gray200,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final statusLabel = _statusLabel(order.status);
    final date = DateTime.tryParse(order.createdAt)?.toLocal();
    final dateStr = date != null
        ? DateFormat("MMM d '·' HH:mm").format(date)
        : '';
    final customerName =
        '${order.user?.firstName ?? '?'} ${order.user?.lastName ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(
              Icons.person_rounded,
              customerName.isEmpty ? '—' : customerName,
              AppColors.gray600,
            ),
            const SizedBox(height: 3),
            _row(
              Icons.store_rounded,
              order.businessPartner.businessName,
              AppColors.infoDark,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip(
                  Icons.shopping_bag_rounded,
                  '${order.orderItems.length} item(s)',
                  AppColors.gray500,
                ),
                const SizedBox(width: 12),
                _chip(
                  Icons.euro_rounded,
                  CurrencyFormatter.format(
                    double.tryParse(order.totalPrice) ?? 0,
                  ),
                  AppColors.successDark,
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String s) => switch (s) {
    'pending' => AppColors.warning,
    'confirmed' || 'preparing' => AppColors.infoDark,
    'ready' || 'ready_for_pickup' || 'out_for_delivery' => AppColors.cyan,
    'delivered' || 'completed' => AppColors.successDark,
    'cancelled' => AppColors.error,
    _ => AppColors.gray400,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Pending',
    'confirmed' => 'Confirmed',
    'preparing' => 'Preparing',
    'ready' => 'Ready',
    'ready_for_pickup' => 'Ready for Pickup',
    'out_for_delivery' => 'Out for Delivery',
    'delivered' => 'Delivered',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => s,
  };
}
