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
