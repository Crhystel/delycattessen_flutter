import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/wallet_models.dart';
import '../utils/transaction_grouping.dart';
import 'transaction_kind_badge.dart';

/// Un día del historial del padre: rótulo "Jueves 22 de octubre" y una tarjeta
/// blanca con sus movimientos separados por divisores.
class TransactionDayGroupView extends StatelessWidget {
  const TransactionDayGroupView({
    super.key,
    required this.group,
    required this.onTap,
    this.isFirst = false,
  });

  final TransactionDayGroup group;
  final ValueChanged<TransactionModel> onTap;

  /// El primer día va a 10 del encabezado; los demás a 14 del día anterior.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final transactions = group.transactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4, isFirst ? 10 : 14, 4, 6),
          child: Text(
            DateFormatter.formatLongCapitalized(group.day),
            style: AppText.secondary.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < transactions.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                TransactionRow(
                  transaction: transactions[i],
                  onTap: () => onTap(transactions[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Fila de un movimiento: círculo con "+" o "−", título, subtítulo de una
/// línea, monto con signo (y debajo, tenue, el saldo que quedó) y la flecha que
/// abre el detalle. Todas las filas reservan la misma columna final para que
/// los montos queden alineados.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final TransactionModel transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = transaction.kind;
    final isFailed = transaction.status == 'failed';
    final subtitle = transactionSubtitle(transaction);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kind.rowBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(kind.rowIcon, size: 18, color: kind.rowForeground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transactionTitle(transaction),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.rowTitle.copyWith(fontSize: 15),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.secondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFailed ? 'Fallida' : signedAmountText(transaction),
                  style: AppText.itemTitle.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isFailed ? AppColors.muted : kind.rowAmountColor,
                  ),
                ),
                if (transaction.balanceAfter case final balance?)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      'Saldo \$${balance.toStringAsFixed(2)}',
                      style: AppText.secondary.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: AppColors.muted.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}
