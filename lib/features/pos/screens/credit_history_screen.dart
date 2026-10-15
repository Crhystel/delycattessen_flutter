import 'package:flutter/material.dart';

import '../../menu/screens/transaction_history_screen.dart';
import '../services/pos_service.dart';
import '../widgets/credit_summary_card.dart';

/// Compras a crédito del docente. Reutiliza [TransactionHistoryScreen] (filas
/// y detalle) y solo aporta la carga y el acumulado del mes.
class CreditHistoryScreen extends StatelessWidget {
  const CreditHistoryScreen({super.key});

  Future<TransactionHistoryData> _load() async {
    final history = await PosService().getCreditHistory();
    return TransactionHistoryData(
      [for (final sale in history.sales) sale.toTransaction()],
      header: CreditSummaryCard(
        month: history.month,
        accumulatedTotal: history.accumulatedTotal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransactionHistoryScreen(
      title: 'Mi crédito',
      loader: _load,
      emptyMessage: 'Tus compras a crédito aparecerán aquí.',
    );
  }
}
