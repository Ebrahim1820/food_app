import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/address_widgets.dart';

void showAddCardSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddCardSheet(),
  );
}

class AddCardSheet extends StatelessWidget {
  const AddCardSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom
        : mq.padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            Text(
              CustomerProfileStrings.addCard,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            const _DialogFormField(
              label: 'Card Number',
              icon: Icons.credit_card_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _DialogFormField(
                    label: 'MM / YY',
                    icon: Icons.date_range_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DialogFormField(
                    label: 'CVV',
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _DialogFormField(
              label: 'Cardholder Name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 24),
            CustomDynamicButton(
              fullWidth: true,
              borderRadius: 14,
              label: CustomerProfileStrings.addCard,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DialogFormField({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.gray400),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
