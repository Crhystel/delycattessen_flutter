import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_stock_badges.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

MenuItem _withAllergens(int id, String name, List<String> allergens) =>
    MenuItem(
      id: id,
      name: name,
      description: '',
      price: 2.0,
      category: 'Snacks',
      ingredients: const [],
      allergens: [
        for (var i = 0; i < allergens.length; i++)
          Allergen(id: id * 10 + i, name: allergens[i]),
      ],
      stock: 10,
    );

final _catalog = {
  1: _withAllergens(1, 'Sánduche', ['Gluten', 'Lácteos']),
  2: _withAllergens(2, 'Cola', ['Lácteos']),
};

/// Opens the detail from a button so the pop and the result can be observed.
Future<List<int>> _open(
  WidgetTester tester, {
  bool canAdd = false,
  Map<int, MenuItem>? catalog,
  Combo? combo,
  StockBadgeBuilder? stockBadge,
}) async {
  tester.view.physicalSize = const Size(411, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final added = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ComboDetailScreen(
                    combo: combo ?? lunchCombo(),
                    itemsById: catalog ?? _catalog,
                    onAdd: canAdd ? added.add : null,
                    stockBadge: stockBadge ?? CatalogStockBadges.low,
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return added;
}

void main() {
  testWidgets('looks like a product: name, price, regular price and saving', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Combo almuerzo'), findsOneWidget);
    expect(find.text('\$3.50'), findsOneWidget);
    final regular = tester.widget<Text>(find.text('\$4.00'));
    expect(regular.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('Ahorras \$0.50'), findsOneWidget);
    expect(find.text('Válido hasta el 31/12/2026'), findsOneWidget);
  });

  testWidgets('lists the dishes it includes with their quantity', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Incluye'), findsOneWidget);
    expect(find.text('Sánduche'), findsOneWidget);
    expect(find.text('Cola ×2'), findsOneWidget);
    expect(find.text('\$2.00 c/u'), findsNWidgets(2));
  });

  testWidgets('shows the allergens of all the dishes without repeats', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Contiene alérgenos'), findsOneWidget);
    expect(find.text('Gluten'), findsOneWidget);
    expect(find.text('Lácteos'), findsOneWidget); // in two dishes, shown once
  });

  testWidgets('has no allergens section when the dishes have none', (
    tester,
  ) async {
    await _open(
      tester,
      catalog: {1: product(1, 'Sánduche', 2.5), 2: product(2, 'Cola', 1.5)},
    );

    expect(find.text('Contiene alérgenos'), findsNothing);
  });

  testWidgets('is read-only without onAdd (parents and teachers)', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(QuantityAddBar), findsNothing);
    expect(find.textContaining('Añadir'), findsNothing);
  });

  testWidgets('with onAdd the bar adds the chosen quantity and closes', (
    tester,
  ) async {
    final added = await _open(tester, canAdd: true);

    expect(find.text('Añadir \$3.50'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('Añadir \$7.00'), findsOneWidget);

    await tester.tap(find.text('Añadir \$7.00'));
    await tester.pumpAndSettle();

    expect(added, [2]);
    expect(find.byType(ComboDetailScreen), findsNothing);
  });

  group('stock', () {
    testWidgets('shows "Quedan N" with few units left', (tester) async {
      await _open(tester, combo: lunchCombo(availableQuantity: 3));

      expect(find.text('Quedan 3'), findsOneWidget);
      expect(find.text('Agotado'), findsNothing);
    });

    testWidgets('shows "Última unidad" with one left', (tester) async {
      await _open(tester, combo: lunchCombo(availableQuantity: 1));

      expect(find.text('Última unidad'), findsOneWidget);
    });

    testWidgets('shows nothing about stock with plenty of units', (
      tester,
    ) async {
      await _open(tester, combo: lunchCombo(availableQuantity: 40));

      expect(find.textContaining('Quedan'), findsNothing);
      expect(find.text('Última unidad'), findsNothing);
    });

    testWidgets('shows nothing about stock without the data', (tester) async {
      await _open(tester);

      expect(find.textContaining('Quedan'), findsNothing);
      expect(find.text('Agotado'), findsNothing);
    });

    testWidgets('the POS can show the exact stock instead', (tester) async {
      await _open(
        tester,
        canAdd: true,
        combo: lunchCombo(availableQuantity: 8),
        stockBadge: CatalogStockBadges.exact,
      );

      expect(find.text('Stock: 8'), findsOneWidget);
    });

    testWidgets('sold out: says Agotado and the add button is disabled', (
      tester,
    ) async {
      final added = await _open(
        tester,
        canAdd: true,
        combo: lunchCombo(availableQuantity: 0),
      );

      // The badge and the disabled button, both reading "Agotado".
      expect(find.text('Agotado'), findsNWidgets(2));
      expect(find.textContaining('Añadir'), findsNothing);
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Agotado').last,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(added, isEmpty);
      expect(find.byType(ComboDetailScreen), findsOneWidget);
    });

    testWidgets('the quantity cannot exceed the available units', (
      tester,
    ) async {
      final added = await _open(
        tester,
        canAdd: true,
        combo: lunchCombo(availableQuantity: 2),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('Añadir \$7.00'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add)); // already at the limit
      await tester.pump();
      expect(find.text('Añadir \$7.00'), findsOneWidget);

      await tester.tap(find.text('Añadir \$7.00'));
      await tester.pumpAndSettle();
      expect(added, [2]);
    });

    testWidgets('without data the quantity has no limit', (tester) async {
      await _open(tester, canAdd: true);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      expect(find.text('Añadir \$17.50'), findsOneWidget);
    });
  });
}
