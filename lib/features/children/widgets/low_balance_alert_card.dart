import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/models/auth_models.dart';
import 'child_avatar.dart';

/// Aviso de Inicio cuando a un hijo le queda poco saldo (o ninguno), con un
/// botón que lleva a Billetera para recargarle. El monto se elige allá.
class LowBalanceAlertCard extends StatelessWidget {
  const LowBalanceAlertCard({
    super.key,
    required this.child,
    required this.onRecharge,
  });

  final Child child;
  final VoidCallback onRecharge;

  @override
  Widget build(BuildContext context) {
    final balance = child.balance ?? 0;
    final isEmpty = balance <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.danger500, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChildAvatar(
                child: child,
                radius: 23,
                statusColor: AppColors.danger500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmpty
                          ? '${child.firstName} se quedó sin saldo'
                          : 'A ${child.firstName} le queda poco saldo',
                      style: AppText.itemTitle,
                    ),
                    Text(
                      isEmpty
                          ? 'No podrá comprar en el bar'
                          : 'Recarga para que pueda comprar',
                      style: AppText.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // With a very large system font the amount shrinks instead of
              // pushing the texts out of the card.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: AppText.amount.copyWith(
                      color: AppColors.danger700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRecharge,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal500,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Recargar a ${child.firstName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.button.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
