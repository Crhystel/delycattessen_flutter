import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Resumen de la pestaña Movimientos: saldo actual (azul) y lo consumido en el
/// mes mostrado (blanca con borde).
///
/// Las dos tarjetas miden lo mismo de alto aunque una etiqueta ocupe dos
/// líneas ("Consumido en septiembre" en un teléfono angosto). Con letra muy
/// grande del sistema se apilan a todo el ancho para que nada se corte.
class WalletSummaryHeader extends StatelessWidget {
  const WalletSummaryHeader({
    super.key,
    required this.balance,
    required this.consumed,
    required this.consumedLabel,
  });

  /// A partir de esta escala de texto las tarjetas pasan a una columna.
  static const double stackTextScale = 1.5;

  final double balance;
  final double consumed;

  /// "Consumido en octubre".
  final String consumedLabel;

  @override
  Widget build(BuildContext context) {
    final balanceTile = _SummaryTile(
      label: 'Saldo actual',
      value: balance,
      color: AppColors.teal500,
      labelColor: AppColors.teal50,
      valueColor: Colors.white,
    );
    final consumedTile = _SummaryTile(
      label: consumedLabel,
      value: consumed,
      color: Colors.white,
      labelColor: AppColors.muted,
      valueColor: AppColors.ink900,
      bordered: true,
    );

    if (MediaQuery.textScalerOf(context).scale(1) >= stackTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          balanceTile,
          const SizedBox(height: AppSpacing.sm),
          consumedTile,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: balanceTile),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: consumedTile),
        ],
      ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 2,
            style: AppText.secondary.copyWith(color: labelColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '\$${value.toStringAsFixed(2)}',
              style: AppText.amount.copyWith(
                fontSize: 24,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
