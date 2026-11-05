import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
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
                    combo: lunchCombo(),
                    itemsById: catalog ?? _catalog,
                    onAdd: canAdd ? added.add : null,
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
}
