import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Bottom bar of the POS menu: empty-cart button, the total and "Continuar".
class PosCartBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final VoidCallback onClear;
  final VoidCallback onContinue;

  const PosCartBar({
    super.key,
    required this.total,
    required this.itemCount,
    required this.onClear,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Vaciar carrito',
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger700),
          ),
          Expanded(
            child: Text(
              '\$${total.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary500,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: onContinue,
            child: Text(
              'Continuar ($itemCount)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
