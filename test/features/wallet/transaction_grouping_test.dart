import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/utils/transaction_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _tx({
  int id = 1,
  String type = 'consumption',
  double amount = 1,
  required DateTime at,
  String status = 'success',
  String displayName = 'Helado',
  String time = '9:55 pm',
}) => TransactionModel(
  id: id,
  displayName: displayName,
  amount: amount,
  gateway: '',
  status: status,
  type: type,
  time: time,
  createdAt: at,
  items: const [],
);

void main() {
  group('groupTransactionsByDay', () {
    test('groups by local day, newest day and newest movement first', () {
      final groups = groupTransactionsByDay([
        _tx(id: 1, at: DateTime(2026, 10, 15, 22, 49)),
        _tx(id: 2, at: DateTime(2026, 10, 22, 8, 5)),
        _tx(id: 3, at: DateTime(2026, 10, 22, 21, 55)),
        _tx(id: 4, at: DateTime(2026, 9, 30, 12)),
      ]);

      expect(groups.map((g) => g.day).toList(), [
        DateTime(2026, 10, 22),
        DateTime(2026, 10, 15),
        DateTime(2026, 9, 30),
      ]);
      expect(groups.first.transactions.map((t) => t.id).toList(), [3, 2]);
    });

    test('does not mutate the received list', () {
      final input = [
        _tx(id: 1, at: DateTime(2026, 10, 1)),
        _tx(id: 2, at: DateTime(2026, 10, 2)),
      ];
      groupTransactionsByDay(input);
      expect(input.map((t) => t.id).toList(), [1, 2]);
    });

    test('empty list gives no groups', () {
      expect(groupTransactionsByDay(const []), isEmpty);
    });
  });

  group('months', () {
    final transactions = [
      _tx(id: 1, at: DateTime(2026, 10, 22)),
      _tx(id: 2, at: DateTime(2026, 10, 3)),
      _tx(id: 3, at: DateTime(2026, 9, 28)),
      _tx(id: 4, at: DateTime(2025, 12, 31)),
    ];

    test('monthsOfTransactions is newest first without repeats', () {
      expect(monthsOfTransactions(transactions), [
        DateTime(2026, 10),
        DateTime(2026, 9),
        DateTime(2025, 12),
      ]);
    });

    test('transactionsInMonth keeps only that month and year', () {
      final october = transactionsInMonth(transactions, DateTime(2026, 10, 15));
      expect(october.map((t) => t.id).toList(), [1, 2]);
      expect(transactionsInMonth(transactions, DateTime(2025, 10)), isEmpty);
    });

    test('monthLabel and consumedInLabel', () {
      expect(monthLabel(DateTime(2026, 10)), 'Octubre 2026');
      expect(consumedInLabel(DateTime(2026, 10)), 'Consumido en octubre');
    });

    test('consumedInMonth adds the shown month only, not failed', () {
      final total = consumedInMonth([
        _tx(amount: 5, at: DateTime(2026, 10, 15)),
        _tx(amount: 1, at: DateTime(2026, 10, 22)),
        _tx(amount: 9, at: DateTime(2026, 9, 30)),
        _tx(amount: 4, at: DateTime(2026, 10, 2), status: 'failed'),
        _tx(type: 'recharge', amount: 20, at: DateTime(2026, 10, 3)),
      ], month: DateTime(2026, 10));
      expect(total, 6);
    });
  });

  group('row texts', () {
    test('consumption uses the typographic minus sign', () {
      final text = signedAmountText(_tx(amount: 1, at: DateTime(2026, 10, 22)));
      expect(text, '−\$1.00');
      expect(text.startsWith('-'), isFalse);
    });

    test('recharge uses plus sign', () {
      expect(
        signedAmountText(
          _tx(type: 'recharge', amount: 10, at: DateTime(2026, 10, 22)),
        ),
        '+\$10.00',
      );
    });

    test('titles and subtitles', () {
      final consumption = _tx(at: DateTime(2026, 10, 22));
      final recharge = _tx(
        type: 'recharge',
        displayName: 'Recarga de saldo',
        at: DateTime(2026, 10, 22),
      );
      expect(transactionTitle(consumption), 'Consumo · Helado');
      expect(transactionSubtitle(consumption), '9:55 pm');
      expect(transactionTitle(recharge), 'Recarga');
      expect(transactionSubtitle(recharge), 'Desde la app');
    });
  });
}
