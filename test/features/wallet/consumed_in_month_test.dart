import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/screens/transaction_history_screen.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _tx({
  required String type,
  required double amount,
  required DateTime at,
  String status = 'success',
}) => TransactionModel(
  id: at.millisecondsSinceEpoch,
  displayName: 'Movimiento',
  amount: amount,
  gateway: '',
  status: status,
  type: type,
  time: '',
  createdAt: at,
  items: const [],
);

void main() {
  final now = DateTime(2026, 11, 10, 12);

  test('adds only the consumptions of the current month', () {
    final total = TransactionHistoryScreen.consumedInMonth([
      _tx(type: 'consumption', amount: 5, at: DateTime(2026, 11, 2)),
      _tx(type: 'consumption', amount: 1.5, at: DateTime(2026, 11, 9)),
      _tx(type: 'consumption', amount: 9, at: DateTime(2026, 10, 30)),
      _tx(type: 'recharge', amount: 20, at: DateTime(2026, 11, 3)),
    ], now: now);

    expect(total, 6.5);
  });

  test('failed consumptions do not count', () {
    final total = TransactionHistoryScreen.consumedInMonth([
      _tx(
        type: 'consumption',
        amount: 4,
        at: DateTime(2026, 11, 2),
        status: 'failed',
      ),
    ], now: now);

    expect(total, 0);
  });
}
