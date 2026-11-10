import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/wallet_models.dart';

/// Presentación de cada tipo de movimiento. Un tipo nuevo = un caso aquí.
extension TransactionKindStyle on TransactionKind {
  String get label => switch (this) {
    TransactionKind.recharge => 'Recarga',
    TransactionKind.consumption => 'Consumo',
  };

  IconData get icon => switch (this) {
    TransactionKind.recharge => Icons.arrow_downward_rounded,
    TransactionKind.consumption => Icons.shopping_bag_outlined,
  };

  Color get color => switch (this) {
    TransactionKind.recharge => AppColors.success700,
    TransactionKind.consumption => AppColors.brand700,
  };

  Color get background => switch (this) {
    TransactionKind.recharge => AppColors.successBg,
    TransactionKind.consumption => AppColors.brand50,
  };

  /// Signo del monto sobre el saldo: las recargas suman, los consumos restan.
  String get sign => this == TransactionKind.recharge ? '+' : '-';

  /// Círculo de la fila del historial del padre: "+" azul claro para recargas
  /// y "−" gris para consumos.
  IconData get rowIcon => switch (this) {
    TransactionKind.recharge => Icons.add,
    TransactionKind.consumption => Icons.remove,
  };

  Color get rowBackground => switch (this) {
    TransactionKind.recharge => AppColors.teal50,
    TransactionKind.consumption => AppColors.ink50,
  };

  Color get rowForeground => switch (this) {
    TransactionKind.recharge => AppColors.teal500,
    TransactionKind.consumption => AppColors.muted,
  };

  /// Color del monto en la fila: verde si entra saldo, tinta si sale.
  Color get rowAmountColor => switch (this) {
    TransactionKind.recharge => AppColors.success700,
    TransactionKind.consumption => AppColors.ink900,
  };
}

/// Insignia "Recarga" / "Consumo" con el color e icono de su tipo.
class TransactionKindBadge extends StatelessWidget {
  final TransactionKind kind;

  const TransactionKindBadge({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kind.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 13, color: kind.color),
          const SizedBox(width: 4),
          Text(
            kind.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: kind.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
