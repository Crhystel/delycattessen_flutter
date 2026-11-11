import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/screens/transaction_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _tx({
  required int id,
  String type = 'consumption',
  double amount = 1,
  required DateTime at,
  String displayName = 'Helado',
}) => TransactionModel(
  id: id,
  displayName: displayName,
  amount: amount,
  gateway: 'payphone',
  status: 'success',
  type: type,
  time: '9:55 pm',
  createdAt: at,
  items: const [],
);

final _data = [
  _tx(id: 1, amount: 1, at: DateTime(2026, 10, 22, 21, 55)),
  _tx(
    id: 2,
    amount: 5,
    at: DateTime(2026, 10, 15, 22, 49),
    displayName: 'Crepes',
  ),
  _tx(
    id: 3,
    type: 'recharge',
    amount: 10,
    at: DateTime(2026, 10, 15, 8),
    displayName: 'Recarga de saldo',
  ),
  _tx(id: 4, amount: 3, at: DateTime(2026, 9, 10), displayName: 'Jugo'),
];

Widget _screen() {
  return MaterialApp(
    home: Scaffold(
      body: TransactionHistoryScreen(
        personName: 'Julieta Venegas',
        balance: 9,
        loader: () async => _data,
      ),
    ),
  );
}

void main() {
  testWidgets('summary, month, day groups and no filter chips', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('Saldo actual'), findsOneWidget);
    expect(find.text('\$9.00'), findsOneWidget);
    expect(find.text('Consumido en octubre'), findsOneWidget);
    expect(find.text('\$6.00'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Octubre 2026'), findsOneWidget);

    expect(find.text('Jueves 22 de octubre'), findsOneWidget);
    expect(find.text('Jueves 15 de octubre'), findsOneWidget);
    expect(find.text('Consumo · Helado'), findsOneWidget);
    expect(find.text('Consumo · Crepes'), findsOneWidget);
    expect(find.text('Recarga'), findsOneWidget);
    expect(find.text('−\$1.00'), findsOneWidget);
    expect(find.text('+\$10.00'), findsOneWidget);
    expect(find.text('Desde la app'), findsOneWidget);

    // September's movement is in another month; no per-row balance.
    expect(find.text('Consumo · Jugo'), findsNothing);
    expect(find.textContaining('Saldo \$'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.textContaining('compras pagadas en efectivo'), findsOneWidget);
  });

  testWidgets('choosing another month filters the list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Octubre 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Elige un mes'), findsOneWidget);
    await tester.tap(find.text('Septiembre 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Consumido en septiembre'), findsOneWidget);
    expect(find.text('Consumo · Jugo'), findsOneWidget);
    expect(find.text('Consumo · Helado'), findsNothing);
  });

  testWidgets('the old consumption history is gone: no purple header, no '
      'type filter', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('Historial de consumo'), findsNothing);
    expect(find.text('Detalles de compra'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });
}
