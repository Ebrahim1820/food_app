import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

// ── Quick add-to-cart button ──────────────────────────────────────────────────
class AddToCartButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddToCartButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add_shopping_cart_rounded,
          size: 18,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
