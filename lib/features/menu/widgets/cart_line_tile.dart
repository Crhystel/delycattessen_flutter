import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Línea de un carrito: nombre, precio, cantidad (–/+) y, si se pasa
/// [onRemove], un botón para quitar el producto completo. Sin [onRemove] el
/// "–" se vuelve papelera cuando la cantidad es 1 (quita el último).
class CartLineTile extends StatelessWidget {
  final String name;
  final double unitPrice;
  final int quantity;

  /// Producto no apto (p. ej. con alérgenos): se resalta en rojo.
  final bool isUnsafe;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onRemove;

  const CartLineTile({
    super.key,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.isUnsafe = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canRemove = onRemove != null;
    // Con botón de quitar aparte, el "–" no baja de 1 (evita dos papeleras).
    final minusIsTrash = !canRemove && quantity == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isUnsafe ? AppColors.danger500 : Colors.grey.shade300,
          width: isUnsafe ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isUnsafe ? AppColors.dangerBg : Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.ink50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood, color: AppColors.secondary500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${unitPrice.toStringAsFixed(2)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.brand700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.ink50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    minusIsTrash ? Icons.delete_outline : Icons.remove,
                    size: 18,
                    color: AppColors.secondary500,
                  ),
                  onPressed: canRemove && quantity <= 1 ? null : onDecrement,
                ),
                Text(
                  '$quantity',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                    color: AppColors.secondary500,
                  ),
                  onPressed: onIncrement,
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              tooltip: 'Quitar del carrito',
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger700,
              ),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
