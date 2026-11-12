import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({Map<String, dynamic> extra = const {}}) => {
  'id': 7,
  'display_name': 'Compra en caja',
  'amount': '3.75',
  'gateway': '',
  'status': 'success',
  'type': 'consumption',
  'time': '13:05',
  'created_at': '2026-10-14T13:05:00',
  'items': <Map<String, dynamic>>[],
  ...extra,
};

TransactionModel _parse(Map<String, dynamic> extra) =>
    TransactionModel.fromJson(_json(extra: extra));

void main() {
  group('TransactionModel balance_after', () {
    test('reads a decimal string', () {
      final tx = _parse({'balance_after': '8.25'});

      expect(tx.balanceAfter, 8.25);
      expect(tx.hasBalanceAfter, isTrue);
    });

    test('reads a number and a zero balance', () {
      expect(_parse({'balance_after': 4}).balanceAfter, 4.0);
      final zero = _parse({'balance_after': '0.00'});
      expect(zero.balanceAfter, 0.0);
      expect(zero.hasBalanceAfter, isTrue);
    });

    test('is null when the backend does not send it', () {
      final tx = _parse({});

      expect(tx.balanceAfter, isNull);
      expect(tx.hasBalanceAfter, isFalse);
    });

    test('is null when it is explicitly null', () {
      final tx = _parse({'balance_after': null});

      expect(tx.balanceAfter, isNull);
      expect(tx.hasBalanceAfter, isFalse);
    });

    test('is null when it cannot be read', () {
      for (final raw in ['abc', '', 'NaN', 'Infinity', <String>[]]) {
        expect(_parse({'balance_after': raw}).balanceAfter, isNull);
      }
    });

    test('a sale adapted for teacher credit has no balance', () {
      final tx = TransactionModel.fromSale(
        id: 1,
        displayName: 'Helado',
        time: '9:55 pm',
        amount: 3.5,
        createdAt: DateTime(2026, 10, 22, 21, 55),
        items: const [],
      );

      expect(tx.hasBalanceAfter, isFalse);
    });
  });
}
