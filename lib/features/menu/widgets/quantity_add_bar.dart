import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import 'detail_bottom_bar_shell.dart';

/// Bottom bar of a detail screen: quantity selector and "Añadir $total". It
/// calls [onAdd] with the chosen quantity and closes the screen.
class QuantityAddBar extends StatefulWidget {
  final double unitPrice;
  final ValueChanged<int> onAdd;

  /// Most units that can be chosen; null = no limit. With zero (or less) there
  /// is nothing to sell: the button reads "Agotado" and does nothing.
  final int? maxQuantity;

  const QuantityAddBar({
    super.key,
    required this.unitPrice,
    required this.onAdd,
    this.maxQuantity,
  });

  @override
  State<QuantityAddBar> createState() => _QuantityAddBarState();
}

class _QuantityAddBarState extends State<QuantityAddBar> {
  int _quantity = 1;

  bool get _soldOut => (widget.maxQuantity ?? 1) <= 0;

  bool get _canAddOne =>
      widget.maxQuantity == null || _quantity < widget.maxQuantity!;

  @override
  Widget build(BuildContext context) {
    return DetailBottomBarShell(
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
                  icon: const Icon(Icons.remove, color: AppColors.secondary500),
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
                  onPressed: _canAddOne
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: PrimaryButton(
              label: _soldOut
                  ? 'Agotado'
                  : 'Añadir \$${(widget.unitPrice * _quantity).toStringAsFixed(2)}',
              onPressed: _soldOut
                  ? null
                  : () {
                      widget.onAdd(_quantity);
                      Navigator.pop(context);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
