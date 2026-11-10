import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../models/wallet_models.dart';
import 'transaction_kind_badge.dart';

/// Comprobante de un consumo, tipo factura: estudiante, fecha, cada producto
/// con su cantidad y valor, y el total.
class ConsumptionInvoice extends StatelessWidget {
  final String studentName;
  final TransactionModel transaction;

  const ConsumptionInvoice({
    super.key,
    required this.studentName,
    required this.transaction,
  });

  static const double _quantityWidth = 44;
  static const double _amountWidth = 68;

  /// "14/10/2026 · 13:05"
  static String formatDate(DateTime date) {
    final local = date.toLocal();
    return '${DateFormatter.formatShort(local)} · '
        '${DateFormat('HH:mm').format(local)}';
  }

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = AppColors.ink900.withValues(alpha: 0.6);
    final divider = Divider(
      height: AppSpacing.xl,
      color: AppColors.ink900.withValues(alpha: 0.12),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estudiante',
                      style: textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    Text(
                      studentName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const TransactionKindBadge(kind: TransactionKind.consumption),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fecha', style: textTheme.bodySmall?.copyWith(color: muted)),
              Text(
                formatDate(transaction.createdAt),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          divider,
          if (transaction.items.isEmpty)
            Text(
              'No hay detalle de productos para este consumo.',
              style: textTheme.bodyMedium?.copyWith(color: muted),
            )
          else ...[
            _buildHeaderRow(textTheme),
            const SizedBox(height: AppSpacing.sm),
            for (final item in transaction.items)
              _buildItemRow(textTheme, item),
          ],
          divider,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '-${_money(transaction.amount)}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(TextTheme textTheme) {
    final style = textTheme.labelMedium?.copyWith(
      color: AppColors.brand700,
      fontWeight: FontWeight.w800,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.brand50,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Expanded(child: Text('Producto', style: style)),
          SizedBox(
            width: _quantityWidth,
            child: Text('Cant.', textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: _amountWidth,
            child: Text('P. unit.', textAlign: TextAlign.right, style: style),
          ),
          SizedBox(
            width: _amountWidth,
            child: Text('Valor', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(TextTheme textTheme, TransactionItemDetail item) {
    final muted = AppColors.ink900.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(item.dishName, style: textTheme.bodyMedium)),
          SizedBox(
            width: _quantityWidth,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: _amountWidth,
            child: Text(
              _money(item.priceAtPurchase),
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          SizedBox(
            width: _amountWidth,
            child: Text(
              _money(item.priceAtPurchase * item.quantity),
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
