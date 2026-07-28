import 'package:flutter/material.dart';
import 'package:food_app/controllers/admin_controller.dart';
import 'package:models/models.dart';
import 'package:design_system/design_system.dart';
import 'package:i18n/i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminOffersTab extends StatelessWidget {
  final AdminController ctrl;
  const AdminOffersTab({super.key, required this.ctrl});

  static const _filters = [
    ('all', 'All'),
    ('active', 'Active'),
    ('upcoming', 'Upcoming'),
    ('soldout', 'Sold Out'),
    ('expired', 'Expired'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchBar(onChanged: (v) => ctrl.offersSearch.value = v),
        _FilterRow(ctrl: ctrl, filters: _filters),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: ctrl.refreshOffers,
            child: Obx(() {
              final list = ctrl.filteredOffers;
              if (ctrl.isLoading.value && list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return _EmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: list.length,
                itemBuilder: (_, i) => _OfferCard(offer: list[i]),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Offer Card ────────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final FoodOfferModel offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = offer.endTime.isBefore(now);
    final isUpcoming = offer.startTime.isAfter(now);
    final isSoldOut = offer.quantityAvailable == 0 && !isExpired;
    final (statusLabel, statusColor) = switch (true) {
      _ when isExpired => ('Expired', AppColors.gray400),
      _ when isSoldOut => ('Sold Out', AppColors.accent),
      _ when isUpcoming => ('Upcoming', AppColors.infoDark),
      _ => ('Active', AppColors.successDark),
    };

    final qtyRatio = (offer.quantityTotal ?? 0) > 0
        ? (offer.quantityAvailable ?? 0) / (offer.quantityTotal ?? 1)
        : 0.0;
    final qtyColor = qtyRatio > 0.5
        ? AppColors.successDark
        : qtyRatio > 0.2
        ? AppColors.accent
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: title + status badge ──────────────────────────────
            Row(
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcon(offer.category),
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (offer.businessPartner != null)
                        Text(
                          offer.businessPartner!.businessName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 10),

            // ── Bottom row: price | qty | time ─────────────────────────────
            Row(
              children: [
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (offer.originalPrice != null &&
                        offer.originalPrice!.isNotEmpty)
                      Text(
                        offer.isWeightBased
                            ? CurrencyFormatter.perKg(
                                double.tryParse(offer.originalPrice ?? '') ?? 0,
                              )
                            : CurrencyFormatter.format(
                                double.tryParse(offer.originalPrice ?? '') ?? 0,
                              ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      offer.isWeightBased
                          ? CurrencyFormatter.perKg(offer.pricePerKg ?? 0)
                          : CurrencyFormatter.format(
                              double.tryParse(offer.price ?? '') ?? 0,
                            ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Quantity bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${offer.quantityAvailable} left',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: qtyColor,
                            ),
                          ),
                          Text(
                            'of ${offer.quantityTotal}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: qtyRatio.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.gray100,
                          valueColor: AlwaysStoppedAnimation<Color>(qtyColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Time info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Ends',
                      style: TextStyle(fontSize: 10, color: AppColors.gray400),
                    ),
                    Text(
                      _formatTime(offer.endTime),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isExpired ? AppColors.gray400 : AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) return DateFormat('MMM d').format(dt);
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return DateFormat('MMM d, HH:mm').format(dt.toLocal());
  }

  IconData _categoryIcon(String cat) => switch (cat.toLowerCase()) {
    'fast_food' || 'fastfood' => Icons.fastfood_rounded,
    'pizza' => Icons.local_pizza_rounded,
    'bakery' || 'bread_pastries' => Icons.breakfast_dining_rounded,
    'restaurant' || 'meals' || 'meal' => Icons.dinner_dining_rounded,
    'supermarket' || 'groceries' || 'grocery' => Icons.shopping_cart_rounded,
    'cafe' || 'caffe' => Icons.local_cafe_rounded,
    'fruits_vegetables' || 'vegetables' || 'fruit' => Icons.eco_rounded,
    'hot_drinks' || 'drinks' => Icons.local_drink_rounded,
    'cheese_dairy' || 'dairy' => Icons.egg_alt_rounded,
    'butcher' || 'meat' => Icons.set_meal_rounded,
    'fish' || 'seafood' => Icons.set_meal_rounded,
    'deli_catering' || 'prepared' => Icons.lunch_dining_rounded,
    'flowers' || 'florist' => Icons.local_florist_rounded,
    'salads' || 'salad' || 'dessert' || 'desserts' => Icons.spa_rounded,
    _ => Icons.fastfood_rounded,
  };
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final AdminController ctrl;
  final List<(String, String)> filters;
  const _FilterRow({required this.ctrl, required this.filters});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = ctrl.offersStatusFilter.value;
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (value, label) = filters[i];
            return FilterChipWidget(
              label: label,
              selected: current == value,
              onTap: () => ctrl.offersStatusFilter.value = value,
            );
          },
        ),
      );
    });
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _ctrl,
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search by title or partner…',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray400),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.gray400,
          ),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
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
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lunch_dining_rounded, size: 48, color: AppColors.gray300),
          SizedBox(height: 12),
          Text(
            'No offers found',
            style: TextStyle(color: AppColors.gray400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
