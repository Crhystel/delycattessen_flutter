import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';

/// Acumulado del mes a crédito del docente.
class CreditSummaryCard extends StatelessWidget {
  /// Mes en formato "YYYY-MM" tal como lo envía el backend.
  final String month;
  final double accumulatedTotal;

  const CreditSummaryCard({
    super.key,
    required this.month,
    required this.accumulatedTotal,
  });

  String get _monthLabel {
    final parts = month.split('-');
    final year = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final monthNumber = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (year == null ||
        monthNumber == null ||
        monthNumber < 1 ||
        monthNumber > 12) {
      return 'este mes';
    }
    return '${DateFormatter.monthName(DateTime(year, monthNumber))} $year';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: AppColors.secondary500,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acumulado de $_monthLabel',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '\$${accumulatedTotal.toStringAsFixed(2)}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
