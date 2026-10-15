import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/menu_models.dart';

/// Distintivo de origen de un pedido: preorden o compra en caja (con el medio
/// de pago), para distinguirlos en la misma lista.
class OrderOriginBadge extends StatelessWidget {
  final OrderOrigin origin;
  final String paymentLabel;

  const OrderOriginBadge({
    super.key,
    required this.origin,
    this.paymentLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final isPos = origin == OrderOrigin.pointOfSale;
    final color = isPos ? AppColors.teal700 : AppColors.secondary700;
    final background = isPos ? AppColors.teal50 : AppColors.secondary50;
    final label = isPos
        ? (paymentLabel.isEmpty ? 'En caja' : 'En caja · $paymentLabel')
        : 'Preorden';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPos ? Icons.point_of_sale : Icons.event_available_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
