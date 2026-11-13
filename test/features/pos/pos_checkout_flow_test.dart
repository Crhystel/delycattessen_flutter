import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:delycattessen_flutter/features/pos/models/sale_models.dart';
import 'package:delycattessen_flutter/features/pos/screens/pos_menu_screen.dart';
import 'package:delycattessen_flutter/features/pos/services/pos_service.dart';
import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MenuItem _item(int id, String name, int stock) => MenuItem(
  id: id,
  name: name,
  description: '',
  price: 2.0,
  category: 'Snacks',
  ingredients: const [],
  allergens: const [],
  stock: stock,
);

/// A server that remembers what was sold: each sale takes one unit of every
/// product, and a product without stock is no longer listed, as the real one
/// does.
class _Server {
  _Server({required this.stock});

  final int stock;
  int soldUnits = 0;
  int menuCalls = 0;

  int get left => stock - soldUnits;
}

class _FakeMenuService extends MenuService {
  _FakeMenuService(this.server);

  final _Server server;

  @override
  Future<List<MenuItem>> getMenu({int? studentId}) async {
    server.menuCalls++;
    return server.left > 0
        ? [_item(2, 'Jugo', server.left), _item(3, 'Galleta', server.left)]
        : const [];
  }

  @override
  Future<CatalogOffers> getActiveOffers({int? studentId}) async =>
      CatalogOffers(
        combos: [
          Combo(
            id: 11,
            name: 'Combo fresco',
            price: 3.0,
            regularPrice: 4.0,
            endDate: DateTime(2026, 12, 31),
            availableQuantity: server.left,
            items: [
              ComboItem(
                productId: 2,
                name: 'Jugo',
                quantity: 1,
                stock: server.left,
              ),
              ComboItem(
                productId: 3,
                name: 'Galleta',
                quantity: 1,
                stock: server.left,
              ),
            ],
          ),
        ],
      );
}

class _FakePosService extends PosService {
  _FakePosService(this.server);

  final _Server server;
  ApiException? error;
  int sales = 0;

  @override
  Future<Sale> createSale(SaleRequest request) async {
    if (error != null) throw error!;
    sales++;
    server.soldUnits++;
    return Sale(
      id: 1,
      paymentMethod: request.paymentMethod,
      totalAmount: 3,
      createdAt: DateTime(2026, 11, 13),
      displayName: 'Combo fresco',
      time: '10:00',
      items: [
        TransactionItemDetail(
          dishName: 'Combo fresco',
          quantity: 1,
          priceAtPurchase: 3,
        ),
      ],
    );
  }
}

const _home = Key('pos-home');

/// The cashier home sits under the menu, as in the app, so a stray extra pop
/// would leave the navigator without routes.
Future<void> _openMenu(
  WidgetTester tester,
  _Server server,
  _FakePosService pos,
) async {
  tester.view.physicalSize = const Size(411, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          key: _home,
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PosMenuScreen(
                    menuService: _FakeMenuService(server),
                    posService: pos,
                  ),
                ),
              ),
              child: const Text('Abrir caja'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir caja'));
  await tester.pumpAndSettle();
}

Future<void> _addComboAndGoToCheckout(WidgetTester tester) async {
  await tester.tap(find.text('Agregar combo'));
  await tester.pumpAndSettle();
  // The "combo added" notification covers the bar for a few seconds.
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Continuar'));
  await tester.pumpAndSettle();
}

Future<void> _charge(WidgetTester tester) async {
  await tester.tap(find.textContaining('Cobrar \$'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Cobrar'));
  // The button spins while the charge is in flight and behind the receipt, so
  // pumpAndSettle would never return.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('selling the last unit goes back home, with no notice', (
    tester,
  ) async {
    final server = _Server(stock: 1);
    final pos = _FakePosService(server);
    await _openMenu(tester, server, pos);
    await _addComboAndGoToCheckout(tester);

    await _charge(tester);
    expect(find.text('¡Venta registrada!'), findsOneWidget);
    await tester.tap(find.text('Nueva venta'));
    // Let the server answer and the routes finish leaving.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(pos.sales, 1);
    expect(find.byKey(_home), findsOneWidget);
    expect(find.text('Abrir caja'), findsOneWidget);
    expect(find.text('Stock actualizado'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selling with stock to spare also goes back home', (
    tester,
  ) async {
    final server = _Server(stock: 5);
    final pos = _FakePosService(server);
    await _openMenu(tester, server, pos);
    await _addComboAndGoToCheckout(tester);

    await _charge(tester);
    await tester.tap(find.text('Nueva venta'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(_home), findsOneWidget);
    expect(find.text('Stock actualizado'), findsNothing);
  });

  testWidgets('a rejected charge stays on the checkout and refreshes stock', (
    tester,
  ) async {
    final server = _Server(stock: 1);
    final pos = _FakePosService(server)
      ..error = ApiException('Saldo insuficiente');
    await _openMenu(tester, server, pos);
    await _addComboAndGoToCheckout(tester);
    final callsBefore = server.menuCalls;

    await _charge(tester);

    expect(find.text('Saldo insuficiente'), findsOneWidget);
    expect(find.text('¡Venta registrada!'), findsNothing);
    expect(find.textContaining('Cobrar \$'), findsOneWidget);
    expect(server.menuCalls, greaterThan(callsBefore));
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('going back from the checkout refreshes the stock', (
    tester,
  ) async {
    final server = _Server(stock: 5);
    final pos = _FakePosService(server);
    await _openMenu(tester, server, pos);
    await _addComboAndGoToCheckout(tester);
    final callsBefore = server.menuCalls;

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('Continuar'), findsOneWidget);
    expect(server.menuCalls, greaterThan(callsBefore));
  });

  testWidgets(
    'stock sold out meanwhile empties the cart and returns to the menu',
    (tester) async {
      final server = _Server(stock: 1);
      final pos = _FakePosService(server)
        ..error = ApiException('Stock insuficiente');
      await _openMenu(tester, server, pos);
      await _addComboAndGoToCheckout(tester);

      // Another cashier sells the last unit; this charge fails and refreshes.
      server.soldUnits = 1;
      await _charge(tester);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(find.byType(PosMenuScreen), findsOneWidget);
      expect(find.textContaining('Cobrar \$'), findsNothing);
      expect(find.textContaining('Continuar'), findsNothing);
      expect(tester.takeException(), isNull);

      // Home is still underneath: backing out of the menu reaches it.
      Navigator.of(tester.element(find.byType(PosMenuScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(_home), findsOneWidget);
    },
  );
}
