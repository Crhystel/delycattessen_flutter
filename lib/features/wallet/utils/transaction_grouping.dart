import '../../../core/utils/date_formatter.dart';
import '../models/wallet_models.dart';

/// Movimientos de un mismo día (hora local), del más reciente al más antiguo.
class TransactionDayGroup {
  /// Medianoche local del día.
  final DateTime day;
  final List<TransactionModel> transactions;

  const TransactionDayGroup(this.day, this.transactions);
}

DateTime _localDay(TransactionModel transaction) {
  final local = transaction.createdAt.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Primer día del mes (hora local) al que pertenece [transaction].
DateTime transactionMonth(TransactionModel transaction) {
  final day = _localDay(transaction);
  return DateTime(day.year, day.month);
}

/// Meses que tienen movimientos, del más reciente al más antiguo y sin
/// repetir.
List<DateTime> monthsOfTransactions(List<TransactionModel> transactions) {
  final months = {for (final t in transactions) transactionMonth(t)}.toList()
    ..sort((a, b) => b.compareTo(a));
  return months;
}

/// Movimientos que caen en [month] (cualquier día de ese mes y año).
List<TransactionModel> transactionsInMonth(
  List<TransactionModel> transactions,
  DateTime month,
) {
  final target = DateTime(month.year, month.month);
  return transactions.where((t) => transactionMonth(t) == target).toList();
}

/// Agrupa por día local, con los días y los movimientos del más reciente al
/// más antiguo. No modifica [transactions].
List<TransactionDayGroup> groupTransactionsByDay(
  List<TransactionModel> transactions,
) {
  final sorted = [...transactions]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final groups = <TransactionDayGroup>[];
  for (final transaction in sorted) {
    final day = _localDay(transaction);
    if (groups.isEmpty || groups.last.day != day) {
      groups.add(TransactionDayGroup(day, []));
    }
    groups.last.transactions.add(transaction);
  }
  return groups;
}

/// Total de consumos del mes de [month] (el mes actual por defecto); no cuenta
/// las fallidas.
double consumedInMonth(List<TransactionModel> transactions, {DateTime? month}) {
  final target = month ?? DateTime.now();
  return transactionsInMonth(transactions, target)
      .where(
        (t) => t.kind == TransactionKind.consumption && t.status != 'failed',
      )
      .fold(0.0, (sum, t) => sum + t.amount);
}

/// "Octubre 2026"
String monthLabel(DateTime month) {
  final name = DateFormatter.monthName(month);
  return '${name[0].toUpperCase()}${name.substring(1)} ${month.year}';
}

/// "Consumido en octubre"
String consumedInLabel(DateTime month) =>
    'Consumido en ${DateFormatter.monthName(month)}';

/// Signo menos tipográfico (U+2212), más ancho y alineado con el "+".
const String minusSign = '−';

/// "−$1.00" para un consumo y "+$5.00" para una recarga.
String signedAmountText(TransactionModel transaction) {
  final sign = transaction.kind == TransactionKind.recharge ? '+' : minusSign;
  return '$sign\$${transaction.amount.toStringAsFixed(2)}';
}

/// "Consumo · Helado" o "Recarga".
String transactionTitle(TransactionModel transaction) {
  if (transaction.kind == TransactionKind.recharge) return 'Recarga';
  return 'Consumo · ${transaction.displayName}';
}

/// Subtítulo de una línea: la hora del consumo o el origen de la recarga.
String transactionSubtitle(TransactionModel transaction) {
  if (transaction.kind == TransactionKind.recharge) return 'Desde la app';
  return transaction.time;
}
