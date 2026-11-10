import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';

/// Tarjeta azul con el saldo del hijo y el botón blanco "Recargar" a todo el
/// ancho. Se superpone a la cabecera morada de la ficha.
class ChildBalanceCard extends StatelessWidget {
  const ChildBalanceCard({
    super.key,
    required this.balance,
    required this.onRecharge,
  });

  final double balance;
  final VoidCallback onRecharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: AppColors.teal500,
        borderRadius: AppRadius.cardAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.balanceShadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Saldo actual',
            style: AppText.secondaryLg.copyWith(
              fontSize: 14,
              color: AppColors.teal50,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: AppText.amount.copyWith(
              fontSize: 38,
              height: 1.05,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onRecharge,
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 18, color: AppColors.teal500),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Recargar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.button.copyWith(
                          fontSize: 15,
                          color: AppColors.teal500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
