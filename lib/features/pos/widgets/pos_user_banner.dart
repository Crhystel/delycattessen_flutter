import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/pos_identification_model.dart';

/// "Vendiendo a ..." box of the POS menu: who the cashier is selling to, the
/// balance or monthly consumption and, in red, the customer's allergies. It
/// stays visible while the rest of the header collapses, because the
/// allergies are safety information.
class PosUserBanner extends StatelessWidget {
  final IdentifiedUser user;

  const PosUserBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAllergies = user.allergies.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasAllergies ? AppColors.dangerBg : AppColors.secondary50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendiendo a ${user.fullName}',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            if (user.displayAmount != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    user.isTeacher
                        ? Icons.receipt_long_outlined
                        : Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: AppColors.ink900,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${user.displayAmountLabel}: '
                      '\$${user.displayAmount!.toStringAsFixed(2)}',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (hasAllergies) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.danger700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Alergias: ${user.allergies.join(', ')}',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
