import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';

/// Resumen de la pestaña Movimientos: saldo actual (azul) y lo consumido en el
/// mes mostrado (blanca con borde).
class WalletSummaryHeader extends StatelessWidget {
  const WalletSummaryHeader({
    super.key,
    required this.balance,
    required this.consumed,
    required this.consumedLabel,
  });

  final double balance;
  final double consumed;

  /// "Consumido en octubre".
  final String consumedLabel;

  @override
  Widget build(BuildContext context) {
    // Both tiles have the same structure (one-line label + amount), so they
    // match in height without stretching (which would need a bounded height).
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Saldo actual',
            value: balance,
            color: AppColors.teal500,
            labelColor: AppColors.teal50,
            valueColor: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: consumedLabel,
            value: consumed,
            color: Colors.white,
            labelColor: AppColors.muted,
            valueColor: AppColors.ink900,
            bordered: true,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.labelColor,
    required this.valueColor,
    this.bordered = false,
  });

  final String label;
  final double value;
  final Color color;
  final Color labelColor;
  final Color valueColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.mdAll,
        border: bordered ? Border.all(color: AppColors.line) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.secondary.copyWith(color: labelColor),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: AppText.amount.copyWith(
              fontSize: 24,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
