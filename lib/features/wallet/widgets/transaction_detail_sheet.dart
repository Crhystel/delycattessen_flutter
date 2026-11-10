import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../models/wallet_models.dart';
import 'consumption_invoice.dart';
import 'transaction_kind_badge.dart';

/// Hoja con el detalle de un movimiento: el comprobante de un consumo o el
/// método, estado y total de una recarga.
Future<void> showTransactionDetail(
  BuildContext context, {
  required TransactionModel transaction,
  required String personName,
}) {
  final kind = transaction.kind;

  if (kind != TransactionKind.recharge) {
    return AppBottomSheet.show<void>(
      context,
      title: transaction.displayName,
      subtitle: ConsumptionInvoice.formatDate(transaction.createdAt),
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        child: ConsumptionInvoice(
          studentName: personName,
          transaction: transaction,
        ),
      ),
    );
  }

  return AppBottomSheet.show<void>(
    context,
    title: transaction.displayName,
    subtitle: transaction.time,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSpacing.xl),
          _DetailRow(
            label: 'Método',
            value: transaction.gateway.isNotEmpty
                ? transaction.gateway
                : 'No especificado',
          ),
          _DetailRow(
            label: 'Estado',
            value: transaction.status == 'failed' ? 'Fallida' : 'Exitosa',
          ),
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
                '${kind.sign}\$${transaction.amount.toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: kind.color,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
