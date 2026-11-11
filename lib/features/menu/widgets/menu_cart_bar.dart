import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Barra al pie del menú del mes: cuántos platos hay en el carrito y para
/// quién, el total y el botón "Confirmar pedido".
class MenuCartBar extends StatelessWidget {
  const MenuCartBar({
    super.key,
    required this.count,
    required this.total,
    required this.childName,
    required this.onConfirm,
  });

  /// Platos en el carrito.
  final int count;
  final double total;

  /// A quién se le pide (ya con el texto por defecto si no hay hijo).
  final String childName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.secondary500,
        borderRadius: AppRadius.mdAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${count == 1 ? '1 plato' : '$count platos'} para $childName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.secondary.copyWith(
                    color: AppColors.secondary50,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: AppText.price.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: AppColors.ink900,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.controlAll,
              ),
              textStyle: AppText.button.copyWith(fontSize: 15),
            ),
            onPressed: onConfirm,
            child: const Text('Confirmar pedido'),
          ),
        ],
      ),
    );
  }
}
