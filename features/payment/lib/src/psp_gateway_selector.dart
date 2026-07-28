import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'customer_payment_strings.dart';
import 'package:design_system/design_system.dart';

/// Shared bank-gateway picker for the "pay online" step of checkout —
/// used by every market (Food, Cosmetic, ...), since choosing a PSP has
/// nothing to do with what's actually being bought. Lists every
/// [PspProvider]; only the ones in [PspProvider.enabledProviders] are
/// tappable, the rest show a "coming soon" badge so the list can grow
/// without any layout change once a provider's API is wired up.
class PspGatewaySelector extends StatelessWidget {
  const PspGatewaySelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final PspProvider? selected;
  final ValueChanged<PspProvider> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PspProvider.values
          .map(
            (provider) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PspTile(
                provider: provider,
                isSelected: selected == provider,
                onTap: provider.isEnabled ? () => onSelect(provider) : null,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PspTile extends StatelessWidget {
  const _PspTile({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  final PspProvider provider;
  final bool isSelected;
  final VoidCallback? onTap;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.gray50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.gray400,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  provider.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!_enabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    CustomerPaymentStrings.gatewayComingSoon,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: AppColors.white,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
