import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:food_app/constants/food/business_constants/business_order_strings.dart';

/// Shown when a tab has no orders. Message is specific to the bucket so it
/// reassures ("you're caught up") rather than alarming, and tells the partner
/// what happens next.
class BusinessEmptyOrders extends StatelessWidget {
  final OrderBucket bucket;
  final bool listening; // show the "listening for orders" chip on the New tab

  const BusinessEmptyOrders({
    super.key,
    required this.bucket,
    this.listening = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final (icon, title, subtitle) = switch (bucket) {
      OrderBucket.incoming => (
        Icons.receipt_long_outlined,
        BusinessEmptyOrdersStrings.incomingTitle,
        BusinessEmptyOrdersStrings.incomingSubtitle,
      ),
      OrderBucket.active => (
        Icons.outdoor_grill_outlined,
        BusinessEmptyOrdersStrings.activeTitle,
        BusinessEmptyOrdersStrings.activeSubtitle,
      ),
      OrderBucket.done => (
        Icons.history,
        BusinessEmptyOrdersStrings.doneTitle,
        BusinessEmptyOrdersStrings.doneSubtitle,
      ),
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (bucket == OrderBucket.incoming && listening) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 15, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      BusinessEmptyOrdersStrings.listeningChip,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
