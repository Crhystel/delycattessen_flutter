import 'package:delycattessen_flutter/features/pos/models/pos_identification_model.dart';
import 'package:delycattessen_flutter/features/pos/models/sale_models.dart';
import 'package:delycattessen_flutter/features/pos/widgets/pos_sale_success_sheet.dart';
import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

IdentifiedUser _student() => IdentifiedUser(
  userId: 1,
  username: 'julieta',
  fullName: 'Julieta Venegas',
  role: 'STUDENT',
  roleDisplay: 'Estudiante',
  balance: 9,
  allergies: const [],
  pendingOrders: const [],
  identificationMethod: 'QR',
);

Sale _sale(PaymentMethod method) => Sale(
  id: 1,
  paymentMethod: method,
  totalAmount: 1,
  createdAt: DateTime(2026, 11, 11),
  displayName: 'Helado',
  time: '10:00',
  items: [
    TransactionItemDetail(dishName: 'Helado', quantity: 1, priceAtPurchase: 1),
  ],
);

Future<void> _open(
  WidgetTester tester, {
  required PaymentMethod method,
  IdentifiedUser? user,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => PosSaleSuccessSheet.show(
              context,
              sale: _sale(method),
              method: method,
              user: user,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wallet sale shows the customer, the item and what is left', (
    tester,
  ) async {
    await _open(tester, method: PaymentMethod.wallet, user: _student());

    expect(find.text('¡Venta registrada!'), findsOneWidget);
    expect(find.text('Se descontó del saldo de la billetera'), findsOneWidget);
    expect(find.text('\$1.00'), findsNWidgets(2)); // total and item line
    expect(find.text('Julieta Venegas'), findsOneWidget);
    expect(find.text('JV'), findsOneWidget);
    expect(find.text('Billetera'), findsOneWidget);
    expect(find.text('1× Helado'), findsOneWidget);
    expect(find.text('Saldo restante de Julieta'), findsOneWidget);
    expect(find.text('\$8.00'), findsOneWidget);
  });

  testWidgets('the only action is "Nueva venta"', (tester) async {
    await _open(tester, method: PaymentMethod.wallet, user: _student());

    expect(find.widgetWithText(ElevatedButton, 'Nueva venta'), findsOneWidget);
    expect(find.text('Cerrar'), findsNothing);
    expect(find.text('Listo'), findsNothing);
    expect(find.byType(TextButton), findsOneWidget); // the test's own opener
  });

  testWidgets('"Nueva venta" closes the receipt', (tester) async {
    await _open(tester, method: PaymentMethod.wallet, user: _student());

    await tester.tap(find.text('Nueva venta'));
    await tester.pumpAndSettle();

    expect(find.text('¡Venta registrada!'), findsNothing);
  });

  testWidgets('a quick cash sale has no customer or balance rows', (
    tester,
  ) async {
    await _open(tester, method: PaymentMethod.cash);

    expect(find.text('¡Venta registrada!'), findsOneWidget);
    expect(find.text('Cobro en efectivo'), findsOneWidget);
    expect(find.text('Cliente'), findsNothing);
    expect(find.textContaining('Saldo restante'), findsNothing);
    expect(find.text('1× Helado'), findsOneWidget);
  });

  testWidgets('fits a small phone without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PosSaleSuccessSheet.show(
                context,
                sale: _sale(PaymentMethod.wallet),
                method: PaymentMethod.wallet,
                user: _student(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
