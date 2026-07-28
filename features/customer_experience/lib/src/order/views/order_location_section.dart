import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:location/location.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';
import 'package:i18n/i18n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where this order is being fulfilled — a single card replacing the old
/// separate "restaurant" and "delivery address" cards.
///
/// Pickup orders (the default — this is a pickup-first marketplace) show the
/// business's address with real "Call" / "Directions" actions, since the
/// customer needs to go there. Delivery orders show the plain delivery
/// address snapshot instead — no directions needed to your own address, and
/// there's no courier/live-tracking concept in this app yet, so we don't
/// fabricate one.
class OrderLocationSection extends StatelessWidget {
  const OrderLocationSection({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final isDelivery = order.isDelivery;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDelivery
                    ? Icons.location_on_rounded
                    : Icons.storefront_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isDelivery
                    ? CustomerOrderStrings.deliveryAddress
                    : CustomerOrderStrings.locationPickupTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isDelivery)
            Text(
              order.deliveryAddress ?? CustomerOrderStrings.noDeliveryAddress,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            )
          else
            _PickupDetails(order: order),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDelivery
                    ? CustomerOrderStrings.estimatedDelivery
                    : CustomerOrderStrings.estimatedPickup,
                style: const TextStyle(color: AppColors.gray600, fontSize: 12),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.estimatedDeliveryLabel ?? '00:00',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickupDetails extends StatelessWidget {
  const _PickupDetails({required this.order});

  final OrderModel order;

  double? get _lat => double.tryParse(order.businessPartner.latitude);
  double? get _lng => double.tryParse(order.businessPartner.longitude);
  bool get _hasCoords => (_lat ?? 0) != 0 && (_lng ?? 0) != 0;
  String? get _phone => order.businessPartner.contactPhone;
  bool get _hasPhone => (_phone ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final locationController = Get.find<LocationController>();
    final distanceKm = DistanceHelper.calculateDistanceKm(
      locationController.userLat.value,
      locationController.userLng.value,
      order.businessPartner.latitude,
      order.businessPartner.longitude,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.businessPartner.businessName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.businessPartner.fullAddress ?? '',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.gray600,
                    ),
                  ),
                  if (distanceKm != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      HelperMethods.formatDistance(distanceKm),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (_hasPhone || _hasCoords) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (_hasCoords)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.directions_rounded,
                    label: CustomerOrderStrings.directionsButton,
                    onTap: () => MapHelper.openMap(
                      latitude: _lat!,
                      longitude: _lng!,
                      label: order.businessPartner.businessName,
                    ),
                  ),
                ),
              if (_hasCoords && _hasPhone) const SizedBox(width: 10),
              if (_hasPhone)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.call_rounded,
                    label: CustomerOrderStrings.callButton,
                    onTap: () => _call(_phone!),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e, st) {
      AppLogger.error(
        'OrderLocationSection',
        'Could not launch $uri',
        error: e,
        stackTrace: st,
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomDynamicButton(
      variant: CustomButtonVariant.outlined,
      borderRadius: 12,
      icon: icon,
      label: label,
      onPressed: onTap,
    );
  }
}
