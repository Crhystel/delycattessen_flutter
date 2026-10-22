import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/widgets/consumption_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _consumption({List<TransactionItemDetail> items = const []}) =>
    TransactionModel(
      id: 1,
      displayName: 'Compra en caja',
      amount: 3.75,
      gateway: '',
      status: 'success',
      type: 'consumption',
      time: '13:05',
      createdAt: DateTime(2026, 10, 14, 13, 5),
      items: items,
    );

Future<void> _pump(WidgetTester tester, TransactionModel transaction) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ConsumptionInvoice(
            studentName: 'Ana Pérez',
            transaction: transaction,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows student, date, columns, products and total', (
    tester,
  ) async {
    await _pump(
      tester,
      _consumption(
        items: [
          TransactionItemDetail(
            dishName: 'Pollo con arroz',
            quantity: 2,
            priceAtPurchase: 1.5,
          ),
          TransactionItemDetail(
            dishName: 'Jugo',
            quantity: 1,
            priceAtPurchase: 0.75,
          ),
        ],
      ),
    );

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('14/10/2026 · 13:05'), findsOneWidget);
    for (final header in ['Producto', 'Cant.', 'P. unit.', 'Valor']) {
      expect(find.text(header), findsOneWidget);
    }
    expect(find.text('Pollo con arroz'), findsOneWidget);
    expect(find.text('\$1.50'), findsOneWidget); // precio unitario
    expect(find.text('\$3.00'), findsOneWidget); // 2 x 1.50
    expect(find.text('Jugo'), findsOneWidget);
    expect(find.text('\$0.75'), findsNWidgets(2)); // unitario y valor
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('-\$3.75'), findsOneWidget);
  });

  testWidgets('keeps the total and explains when there are no products', (
    tester,
  ) async {
    await _pump(tester, _consumption());

    expect(
      find.text('No hay detalle de productos para este consumo.'),
      findsOneWidget,
    );
    expect(find.text('Producto'), findsNothing);
    expect(find.text('-\$3.75'), findsOneWidget);
  });

  test('formatDate uses day/month/year and 24h time', () {
    expect(
      ConsumptionInvoice.formatDate(DateTime(2026, 1, 5, 9, 7)),
      '05/01/2026 · 09:07',
    );
  });
}
