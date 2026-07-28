// Customer — Payment Methods Screen
//
// Displays the user's saved payment cards and other payment options (e.g.
// PayPal). Each card shows the masked number, expiry and a "Default" badge for
// the primary card. An "Add Payment Method" button at the bottom opens a sheet.
// Cards are currently mocked — wire to a real payment controller when ready.

import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:food_app/utils/currency_formatter.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:food_app/profile_and_orders/profile/views/icon_list_tile.dart';
import 'package:food_app/profile_and_orders/profile/views/section_label.dart';
import 'package:food_app/profile_and_orders/orders/views/add_card_sheet.dart';

// Mock data — replace with real payment controller / model
class _MockCard {
  final String last4;
  final String brand;
  final String expiry;
  final bool isDefault;
  final IconData icon;

  const _MockCard({
    required this.last4,
    required this.brand,
    required this.expiry,
    required this.isDefault,
    required this.icon,
  });
}

const _mockCards = [
  _MockCard(
    last4: '4242',
    brand: 'Visa',
    expiry: '08/27',
    isDefault: true,
    icon: Icons.credit_card_rounded,
  ),
  _MockCard(
    last4: '1234',
    brand: 'Mastercard',
    expiry: '03/26',
    isDefault: false,
    icon: Icons.credit_card_rounded,
  ),
];

class CustomerPaymentMethodsScreen extends StatelessWidget {
  const CustomerPaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          CustomerProfileStrings.paymentMethods,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // ── Saved cards section ──────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.paymentSectionSaved),
            const SizedBox(height: 10),
            ..._mockCards.map((c) => _CardTile(card: c)),

            const SizedBox(height: 20),

            // ── Other payment options ────────────────────────────────────────
            SectionLabel(CustomerProfileStrings.paymentSectionOther),
            const SizedBox(height: 10),
            IconListTile(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.infoDark,
              title: 'PayPal',
              subtitle: 'Connect your PayPal account',
              onTap: () {},
            ),
            IconListTile(
              icon: Icons.apple_rounded,
              iconColor: AppColors.ink,
              title: 'Apple Pay',
              subtitle: 'Pay with Face ID or Touch ID',
              onTap: () {},
            ),
            IconListTile(
              icon: Icons.g_mobiledata_rounded,
              iconColor: const Color(0xFF4285F4),
              title: 'Google Pay',
              subtitle: 'Pay with your Google account',
              onTap: () {},
            ),

            const SizedBox(height: 28),

            // ── Add card button ──────────────────────────────────────────────
            CustomDynamicButton(
              variant: CustomButtonVariant.outlined,
              fullWidth: true,
              borderRadius: 14,
              icon: Icons.add_rounded,
              label: CustomerProfileStrings.addCard,
              onPressed: () => _showAddCardSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) => showAddCardSheet(context);
}

// ── Saved card tile ───────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final _MockCard card;
  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isDefault ? AppColors.primary : AppColors.divider,
          width: card.isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Card brand icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),

          // Card info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${card.brand} · ••••${CurrencyFormatter.localizeDigits(card.last4)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (card.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          CustomerProfileStrings.defaultCard,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  CustomerProfileStrings.cardExpires(
                    CurrencyFormatter.localizeDigits(card.expiry),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AppColors.gray400,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
