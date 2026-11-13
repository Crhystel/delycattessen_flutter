import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/allergen_section_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_stock_badges.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_chip.dart';
import 'package:delycattessen_flutter/features/menu/widgets/other_combos_grid.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

const _pepito = AllergenAudience.named('Pepito');

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
  AllergenAdvisory advisory = const AllergenAdvisory(),
  List<Combo> otherCombos = const [],
  ValueChanged<Combo>? onComboTap,
  int? availableQuantity,
}) async {
  tester.view.physicalSize = const Size(411, 1400);
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
                    advisory: advisory,
                    otherCombos: otherCombos,
                    onComboTap: onComboTap,
                    availableQuantity: availableQuantity,
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
  testWidgets('header: tag, name, price, regular price and saving', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('COMBO'), findsOneWidget);
    expect(find.text('Combo almuerzo'), findsOneWidget);
    expect(find.text('\$3.50'), findsOneWidget);
    final regular = tester.widget<Text>(find.text('\$4.00'));
    expect(regular.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('Ahorras \$0.50'), findsOneWidget);
  });

  testWidgets('info tiles: valid until and bought at the POS', (tester) async {
    await _open(tester);

    expect(find.text('Válido hasta'), findsOneWidget);
    expect(find.text('Jueves 31 de diciembre'), findsOneWidget);
    expect(find.text('Se compra'), findsOneWidget);
    expect(find.text('En caja'), findsOneWidget);
  });

  group('Incluye', () {
    testWidgets('lists the dishes with quantity and separate price', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Incluye'), findsOneWidget);
      expect(find.text('1× Sánduche'), findsOneWidget);
      expect(find.text('2× Cola'), findsOneWidget);
      expect(find.text('\$2.00 por separado'), findsNWidgets(2));
    });

    testWidgets('the strip compares the separate price with the combo', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Por separado \$4.00'), findsOneWidget);
      expect(find.text('En combo \$3.50'), findsOneWidget);
    });

    testWidgets('without saving there is no strip nor "Ahorras"', (
      tester,
    ) async {
      await _open(
        tester,
        combo: Combo(
          id: 11,
          name: 'Combo igual',
          price: 4.00,
          regularPrice: 4.00,
          endDate: DateTime(2026, 12, 31),
          items: const [ComboItem(productId: 1, name: 'Sánduche', quantity: 1)],
        ),
      );

      expect(find.textContaining('Ahorras'), findsNothing);
      expect(find.textContaining('En combo'), findsNothing);
      expect(find.text('1× Sánduche'), findsOneWidget);
    });

    testWidgets('a dish missing from the catalog omits its price', (
      tester,
    ) async {
      await _open(tester, catalog: const {});

      expect(find.text('1× Sánduche'), findsOneWidget);
      expect(find.textContaining('por separado'), findsNothing);
    });
  });

  group('allergens', () {
    final conflict = AllergenAdvisory.of(
      allergens: ['Gluten', 'Lácteos'],
      conflicts: ['Gluten'],
      audience: _pepito,
    );

    testWidgets('conflict: chips, red box and blocked bar (POS)', (
      tester,
    ) async {
      final added = await _open(tester, canAdd: true, advisory: conflict);

      expect(find.byType(AllergenSectionCard), findsOneWidget);
      expect(find.byType(DetailChip), findsNWidgets(2));
      expect(find.text('Contiene gluten'), findsOneWidget);
      expect(
        find.text(
          'Pepito tiene registrada esta alergia, por eso este combo no se le puede vender.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BlockedPurchaseBar), findsOneWidget);
      expect(find.text('No disponible para Pepito'), findsOneWidget);
      expect(find.byType(QuantityAddBar), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(added, isEmpty);
    });

    testWidgets('conflict without onAdd: the notice but no bar', (
      tester,
    ) async {
      await _open(tester, advisory: conflict);

      expect(find.text('Contiene gluten'), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsNothing);
      expect(find.byType(QuantityAddBar), findsNothing);
    });

    testWidgets('no conflict: green box and the quantity bar', (tester) async {
      await _open(
        tester,
        canAdd: true,
        advisory: AllergenAdvisory.of(
          allergens: ['Gluten', 'Lácteos'],
          audience: _pepito,
        ),
      );

      expect(
        find.text('Pepito no tiene registradas estas alergias.'),
        findsOneWidget,
      );
      expect(find.textContaining('Contiene'), findsNothing);
      expect(find.byType(QuantityAddBar), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsNothing);
    });

    testWidgets('unknown customer: only the chips', (tester) async {
      await _open(
        tester,
        canAdd: true,
        advisory: AllergenAdvisory.of(allergens: ['Gluten', 'Lácteos']),
      );

      expect(find.byType(DetailChip), findsNWidgets(2));
      expect(find.textContaining('registrada'), findsNothing);
      expect(find.byType(QuantityAddBar), findsOneWidget);
    });

    testWidgets('the card is always there, even without allergens', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Alérgenos'), findsOneWidget);
      expect(find.text('Sin alérgenos registrados'), findsOneWidget);
    });

    testWidgets('the allergens do not depend on the catalog', (tester) async {
      await _open(
        tester,
        catalog: const {},
        advisory: AllergenAdvisory.of(allergens: ['Soya']),
      );

      expect(find.text('Soya'), findsOneWidget);
    });
  });

  group('Otros combos', () {
    final others = [
      lunchCombo(name: 'Combo desayuno'),
      lunchCombo(name: 'Combo merienda'),
    ];

    testWidgets('are listed and tapping one reports it', (tester) async {
      final tapped = <Combo>[];
      await _open(tester, otherCombos: others, onComboTap: tapped.add);

      expect(find.byType(OtherCombosGrid), findsOneWidget);
      expect(find.text('Otros combos'), findsOneWidget);
      expect(find.text('Combo desayuno'), findsOneWidget);

      await tester.ensureVisible(find.text('Combo merienda'));
      await tester.tap(find.text('Combo merienda'));
      await tester.pump();
      expect(tapped.map((c) => c.name), ['Combo merienda']);
    });

    testWidgets('are hidden when there are none', (tester) async {
      await _open(tester);

      expect(find.text('Otros combos'), findsNothing);
      expect(find.byType(OtherCombosGrid), findsNothing);
    });

    testWidgets('without a callback tapping does nothing', (tester) async {
      await _open(tester, otherCombos: others);

      await tester.ensureVisible(find.text('Combo desayuno'));
      await tester.tap(find.text('Combo desayuno'));
      await tester.pumpAndSettle();
      expect(find.byType(ComboDetailScreen), findsOneWidget);
    });
  });

  testWidgets('is read-only without onAdd (parents and teachers)', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(QuantityAddBar), findsNothing);
    expect(find.byType(BlockedPurchaseBar), findsNothing);
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

    testWidgets('units left once the POS cart is taken out replace the own', (
      tester,
    ) async {
      final added = await _open(
        tester,
        canAdd: true,
        combo: lunchCombo(availableQuantity: 8),
        stockBadge: CatalogStockBadges.exact,
        availableQuantity: 2,
      );

      expect(find.text('Stock: 2'), findsOneWidget);
      expect(find.text('Stock: 8'), findsNothing);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.textContaining('Añadir'));
      await tester.pumpAndSettle();
      expect(added, [2]);
    });

    testWidgets('none left in the POS cart sells the combo out', (
      tester,
    ) async {
      final added = await _open(
        tester,
        canAdd: true,
        combo: lunchCombo(availableQuantity: 8),
        stockBadge: CatalogStockBadges.exact,
        availableQuantity: 0,
      );

      expect(find.text('Agotado'), findsNWidgets(2));
      expect(find.textContaining('Stock:'), findsNothing);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(added, isEmpty);
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
