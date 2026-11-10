import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';

/// Bottom bar of a detail screen: quantity selector and "Añadir $total". It
/// calls [onAdd] with the chosen quantity and closes the screen.
class QuantityAddBar extends StatefulWidget {
  final double unitPrice;
  final ValueChanged<int> onAdd;

  const QuantityAddBar({
    super.key,
    required this.unitPrice,
    required this.onAdd,
  });

  @override
  State<QuantityAddBar> createState() => _QuantityAddBarState();
}

class _QuantityAddBarState extends State<QuantityAddBar> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary500),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                      color: AppColors.secondary500,
                    ),
                    tooltip: 'Quitar uno',
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.secondary500),
                    tooltip: 'Agregar uno',
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: PrimaryButton(
                label:
                    'Añadir \$${(widget.unitPrice * _quantity).toStringAsFixed(2)}',
                onPressed: () {
                  widget.onAdd(_quantity);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
