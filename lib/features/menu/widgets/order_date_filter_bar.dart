import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../utils/order_filters.dart';

/// Filtro de pedidos por periodo (Todos / Hoy / Esta semana / Este mes).
class OrderDateFilterBar extends StatelessWidget {
  final OrderDateRange selected;
  final ValueChanged<OrderDateRange> onSelected;

  const OrderDateFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: OrderDateRange.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final range = OrderDateRange.values[index];
          return ChoiceChip(
            label: Text(range.label),
            selected: range == selected,
            onSelected: (_) => onSelected(range),
          );
        },
      ),
    );
  }
}
