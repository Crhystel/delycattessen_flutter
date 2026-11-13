import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/allergen_section_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_link_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MenuItem _item({
  int stock = 10,
  String category = 'Bebidas',
  List<Allergen>? allergens,
  List<Ingredient>? ingredients,
}) => MenuItem(
  id: 2,
  name: 'Cola',
  description: 'Bebida fría',
  price: 1.60,
  category: category,
  ingredients: ingredients ?? [Ingredient(id: 1, name: 'Azúcar')],
  allergens: allergens ?? [Allergen(id: 3, name: 'Cafeína')],
  stock: stock,
);

final _promo = Combo(
  id: 9,
  name: 'Promo barata',
  price: 2.0,
  regularPrice: 7.0,
  endDate: DateTime(2026, 12, 31),
  items: const [ComboItem(productId: 2, name: 'Cola', quantity: 1)],
);

final _conflict = AllergenAdvisory.of(
  allergens: ['Cafeína', 'Gluten'],
  conflicts: ['Cafeína'],
  audience: const AllergenAudience.named('Pepito'),
);

final _safe = AllergenAdvisory.of(
  allergens: ['Cafeína'],
  audience: const AllergenAudience.named('Pepito'),
);

Future<void> _pump(
  WidgetTester tester, {
  MenuItem? item,
  ValueChanged<int>? onAdd,
  AllergenAdvisory advisory = const AllergenAdvisory(),
  List<Combo> combos = const [],
  ValueChanged<Combo>? onComboTap,
  bool exactStock = false,
  int? maxQuantity,
}) async {
  tester.view.physicalSize = const Size(411, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  item: item ?? _item(),
                  onAdd: onAdd,
                  advisory: advisory,
                  combos: combos,
                  onComboTap: onComboTap,
                  exactStock: exactStock,
                  maxQuantity: maxQuantity,
                ),
              ),
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
  testWidgets('shows the category, name, description, price and tiles', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Bebidas'), findsOneWidget);
    expect(find.text('Cola'), findsOneWidget);
    expect(find.text('Bebida fría'), findsOneWidget);
    expect(find.text('\$1.60'), findsOneWidget);
    expect(find.text('Disponibles hoy'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Se compra'), findsOneWidget);
    expect(find.text('En caja'), findsOneWidget);
  });

  testWidgets('an uncategorized product still has a tag', (tester) async {
    await _pump(tester, item: _item(category: ''));

    expect(find.text('Producto'), findsOneWidget);
  });

  group('stock tile', () {
    testWidgets('few units left', (tester) async {
      await _pump(tester, item: _item(stock: 3));

      expect(find.text('Quedan 3'), findsOneWidget);
    });

    testWidgets('sold out', (tester) async {
      await _pump(tester, item: _item(stock: 0));

      expect(find.text('Agotado'), findsOneWidget);
    });

    testWidgets('exact count at the POS', (tester) async {
      await _pump(tester, item: _item(stock: 8), exactStock: true);

      expect(find.text('8 unidades'), findsOneWidget);
      expect(find.text('Disponible'), findsNothing);
    });
  });

  group('quantity cap from the POS cart', () {
    testWidgets('a cap of zero reads Agotado and adds nothing', (tester) async {
      final added = <int>[];
      await _pump(
        tester,
        item: _item(stock: 8),
        onAdd: added.add,
        exactStock: true,
        maxQuantity: 0,
      );

      expect(find.text('0 unidades'), findsNothing);
      expect(find.text('Agotado'), findsWidgets);
      expect(find.textContaining('Añadir'), findsNothing);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(added, isEmpty);
    });

    testWidgets('the cap, not the server stock, limits the quantity', (
      tester,
    ) async {
      final added = <int>[];
      await _pump(
        tester,
        item: _item(stock: 8),
        onAdd: added.add,
        exactStock: true,
        maxQuantity: 2,
      );

      expect(find.text('2 unidades'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.textContaining('Añadir'));
      await tester.pumpAndSettle();

      expect(added, [2]);
    });

    testWidgets('without a cap nothing changes', (tester) async {
      final added = <int>[];
      await _pump(tester, item: _item(stock: 8), onAdd: added.add);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      await tester.tap(find.textContaining('Añadir'));
      await tester.pumpAndSettle();

      expect(added, [5]);
    });
  });

  group('allergens', () {
    testWidgets('the card shows even when the product has none', (
      tester,
    ) async {
      await _pump(tester, item: _item(allergens: const []));

      expect(find.byType(AllergenSectionCard), findsOneWidget);
      expect(find.text('Alérgenos'), findsOneWidget);
      expect(find.text('Sin alérgenos registrados'), findsOneWidget);
    });

    testWidgets('with a conflict: red box, chips and a blocked bar', (
      tester,
    ) async {
      await _pump(tester, onAdd: (_) {}, advisory: _conflict);

      expect(find.text('Cafeína'), findsOneWidget);
      expect(find.text('Gluten'), findsOneWidget);
      expect(find.text('Contiene cafeína'), findsOneWidget);
      expect(
        find.text(
          'Pepito tiene registrada esta alergia, por eso este producto no se '
          'le puede vender.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BlockedPurchaseBar), findsOneWidget);
      expect(find.text('No disponible para Pepito'), findsOneWidget);
      expect(find.byType(QuantityAddBar), findsNothing);
    });

    testWidgets('with a conflict and no onAdd there is no bar at all', (
      tester,
    ) async {
      await _pump(tester, advisory: _conflict);

      expect(find.text('Contiene cafeína'), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsNothing);
      expect(find.byType(QuantityAddBar), findsNothing);
    });

    testWidgets('own allergies say "Tienes registrada"', (tester) async {
      await _pump(
        tester,
        advisory: AllergenAdvisory.of(
          allergens: ['Cafeína'],
          conflicts: ['Cafeína'],
          audience: AllergenAudience.self,
        ),
      );

      expect(
        find.text(
          'Tienes registrada esta alergia, por eso este producto no se te '
          'puede vender.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('without a conflict: green box and the quantity bar', (
      tester,
    ) async {
      await _pump(tester, onAdd: (_) {}, advisory: _safe);

      expect(
        find.text('Pepito no tiene registrada esta alergia.'),
        findsOneWidget,
      );
      expect(find.textContaining('Contiene'), findsNothing);
      expect(find.byType(QuantityAddBar), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsNothing);
    });

    testWidgets('an unidentified customer gets only the chips', (tester) async {
      await _pump(
        tester,
        onAdd: (_) {},
        advisory: AllergenAdvisory.of(allergens: ['Cafeína']),
      );

      expect(find.text('Cafeína'), findsOneWidget);
      expect(find.textContaining('registrada'), findsNothing);
      expect(find.byType(QuantityAddBar), findsOneWidget);
    });
  });

  group('ingredients', () {
    testWidgets('are listed when there are some', (tester) async {
      await _pump(tester);

      expect(find.text('Ingredientes'), findsOneWidget);
      expect(find.text('Azúcar'), findsOneWidget);
    });

    testWidgets('the card is left out when there are none', (tester) async {
      await _pump(tester, item: _item(ingredients: const []));

      expect(find.text('Ingredientes'), findsNothing);
    });
  });

  group('También en combo', () {
    testWidgets('lists the combos and opens the tapped one', (tester) async {
      final tapped = <Combo>[];
      await _pump(tester, combos: [_promo], onComboTap: tapped.add);

      expect(find.text('También en combo'), findsOneWidget);
      expect(find.text('Promo barata'), findsOneWidget);

      await tester.ensureVisible(find.byType(ComboLinkCard));
      await tester.tap(find.byType(ComboLinkCard));
      expect(tapped, [_promo]);
    });

    testWidgets('is hidden without combos', (tester) async {
      await _pump(tester);

      expect(find.text('También en combo'), findsNothing);
    });

    testWidgets('the cards do nothing without onComboTap', (tester) async {
      await _pump(tester, combos: [_promo]);

      await tester.ensureVisible(find.byType(ComboLinkCard));
      await tester.tap(find.byType(ComboLinkCard));
      await tester.pump();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('is read-only without onAdd', (tester) async {
    await _pump(tester);

    expect(find.byType(QuantityAddBar), findsNothing);
    expect(find.byType(BlockedPurchaseBar), findsNothing);
  });

  testWidgets('with onAdd it adds the quantity and closes', (tester) async {
    final added = <int>[];
    await _pump(tester, onAdd: added.add);

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('Añadir \$4.80'), findsOneWidget);

    await tester.tap(find.text('Añadir \$4.80'));
    await tester.pumpAndSettle();

    expect(added, [3]);
    expect(find.byType(ProductDetailScreen), findsNothing);
  });

  testWidgets('the quantity never goes below one', (tester) async {
    await _pump(tester, onAdd: (_) {});

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.text('Añadir \$1.60'), findsOneWidget);
  });
}
