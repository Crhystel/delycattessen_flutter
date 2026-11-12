import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/widgets/transaction_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _balanceLabel = 'Saldo después del movimiento';

TransactionModel _tx({
  required String type,
  double amount = 10,
  double? balanceAfter,
  String status = 'success',
}) => TransactionModel(
  id: 1,
  displayName: type == 'recharge' ? 'Recarga de saldo' : 'Compra en caja',
  amount: amount,
  gateway: 'payphone',
  status: status,
  type: type,
  time: '13:05',
  createdAt: DateTime(2026, 10, 14, 13, 5),
  items: const [],
  balanceAfter: balanceAfter,
);

Future<void> _open(WidgetTester tester, TransactionModel transaction) async {
  // Wide enough for the test font (every glyph is a full em wide).
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showTransactionDetail(
              context,
              transaction: transaction,
              personName: 'Ana Pérez',
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  // The balance left after a movement lives in the list row, not here.
  group('recharge sheet', () {
    testWidgets('shows the total and no balance line', (tester) async {
      await _open(tester, _tx(type: 'recharge', balanceAfter: 18.5));

      expect(find.text('+\$10.00'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(_balanceLabel), findsNothing);
      expect(find.text('\$18.50'), findsNothing);
    });
  });

  group('consumption sheet', () {
    testWidgets('shows the total and no balance line', (tester) async {
      await _open(tester, _tx(type: 'consumption', balanceAfter: 6.25));

      expect(find.text('-\$10.00'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(_balanceLabel), findsNothing);
      expect(find.text('\$6.25'), findsNothing);
    });
  });
}
