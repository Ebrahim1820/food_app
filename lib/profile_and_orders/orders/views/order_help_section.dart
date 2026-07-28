import 'package:flutter/material.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/profile_and_orders/profile/views/customer_help_screen.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/utils/app_logger.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Need help?" card at the bottom of the order detail screen — one tap to
/// call/email the business directly, one tap into the app's general Help
/// centre. Replaces the old plain "Contact support" text button, which did
/// nothing (`onPressed: () {}`).
class OrderHelpSection extends StatelessWidget {
  const OrderHelpSection({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final phone = order.businessPartner.contactPhone;
    final email = order.businessPartner.contactEmail;
    final hasBusinessContact =
        (phone?.trim().isNotEmpty ?? false) ||
        (email?.trim().isNotEmpty ?? false);

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
              const Icon(
                Icons.support_agent_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                CustomerOrderStrings.helpTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CustomerOrderStrings.helpSubtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (hasBusinessContact) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactBusiness(phone, email),
                    icon: const Icon(Icons.storefront_outlined, size: 16),
                    label: Text(
                      CustomerOrderStrings.contactBusinessButton,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Get.to(() => const CustomerHelpScreen()),
                  icon: const Icon(Icons.headset_mic_outlined, size: 16),
                  label: Text(
                    CustomerOrderStrings.contactSupport,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _contactBusiness(String? phone, String? email) async {
    final uri = (phone?.trim().isNotEmpty ?? false)
        ? Uri.parse('tel:${phone!.trim()}')
        : Uri.parse('mailto:${email!.trim()}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e, st) {
      AppLogger.error(
        'OrderHelpSection',
        'Could not launch $uri',
        error: e,
        stackTrace: st,
      );
    }
  }
}
