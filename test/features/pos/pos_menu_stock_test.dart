import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_item_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_offer_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:delycattessen_flutter/features/pos/screens/pos_menu_screen.dart';
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

/// Jugo has one unit, Galleta three, and the combo uses one of each.
class _LowStockMenuService extends MenuService {
  @override
  Future<List<MenuItem>> getMenu({int? studentId}) async => [
    _item(2, 'Jugo', 1),
    _item(3, 'Galleta', 3),
  ];

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
            availableQuantity: 1,
            items: const [
              ComboItem(productId: 2, name: 'Jugo', quantity: 1, stock: 1),
              ComboItem(productId: 3, name: 'Galleta', quantity: 1, stock: 3),
            ],
          ),
        ],
      );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(411, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: PosMenuScreen(menuService: _LowStockMenuService())),
  );
  await tester.pumpAndSettle();
}

Finder _productCard(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(CatalogItemCard));

Finder _inProductCard(String name, String text) => find.descendant(
  of: find.ancestor(
    of: find.text(name),
    matching: find.byType(CatalogItemCard),
  ),
  matching: find.text(text),
);

Finder _inComboCard(String text) =>
    find.descendant(of: find.byType(ComboOfferCard), matching: find.text(text));

/// Opens the detail of a product from its own card (its name also appears
/// inside the combo card).
Future<void> _openProduct(WidgetTester tester, String name) async {
  await tester.tap(
    find
        .descendant(of: find.byType(CatalogItemCard), matching: find.text(name))
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _addCombo(WidgetTester tester) async {
  await tester.tap(find.text('Agregar combo'));
  await tester.pumpAndSettle();
  // The "combo added" notification covers the list for a few seconds.
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('before anything is in the cart the server stock is shown', (
    tester,
  ) async {
    await _pump(tester);

    expect(_inProductCard('Jugo', 'Stock: 1'), findsOneWidget);
    expect(_inProductCard('Galleta', 'Stock: 3'), findsOneWidget);
    expect(_inComboCard('Stock: 1'), findsOneWidget);
    expect(find.text('Agotado'), findsNothing);
    expect(find.text('Agregar combo'), findsOneWidget);
  });

  testWidgets('adding the combo takes its products out of the stock shown', (
    tester,
  ) async {
    await _pump(tester);

    await _addCombo(tester);

    expect(_inProductCard('Jugo', 'Agotado'), findsOneWidget);
    expect(_inProductCard('Jugo', 'Stock: 1'), findsNothing);
    expect(_inProductCard('Galleta', 'Stock: 2'), findsOneWidget);
  });

  testWidgets('the combo is sold out as soon as nothing is left to add', (
    tester,
  ) async {
    await _pump(tester);

    await _addCombo(tester);

    expect(_inComboCard('Agotado'), findsOneWidget);
    expect(_inComboCard('1 en carrito'), findsOneWidget);
    expect(find.text('Agregar combo'), findsNothing);
  });

  testWidgets('a sold out product is dimmed but still opens its detail', (
    tester,
  ) async {
    await _pump(tester);
    await _addCombo(tester);

    expect(tester.widget<CatalogItemCard>(_productCard('Jugo')).dimmed, isTrue);
    expect(
      tester.widget<CatalogItemCard>(_productCard('Galleta')).dimmed,
      isFalse,
    );

    await _openProduct(tester, 'Jugo');

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QuantityAddBar),
        matching: find.text('Agotado'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the detail of the sold out combo cannot add more', (
    tester,
  ) async {
    await _pump(tester);
    await _addCombo(tester);

    await tester.tap(find.text('Combo fresco').first);
    await tester.pumpAndSettle();

    expect(find.byType(ComboDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QuantityAddBar),
        matching: find.text('Agotado'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('emptying the cart gives the stock back', (tester) async {
    await _pump(tester);
    await _addCombo(tester);

    await tester.tap(find.byTooltip('Vaciar carrito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaciar'));
    await tester.pumpAndSettle();

    expect(_inProductCard('Jugo', 'Stock: 1'), findsOneWidget);
    expect(_inProductCard('Galleta', 'Stock: 3'), findsOneWidget);
    expect(_inComboCard('Stock: 1'), findsOneWidget);
    expect(find.text('Agregar combo'), findsOneWidget);
  });

  testWidgets('a loose product also takes stock away from the combo', (
    tester,
  ) async {
    await _pump(tester);

    await _openProduct(tester, 'Jugo');
    await tester.tap(find.textContaining('Añadir'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(_inProductCard('Jugo', 'Agotado'), findsOneWidget);
    expect(_inComboCard('Agotado'), findsOneWidget);
    expect(find.text('Agregar combo'), findsNothing);
  });
}
