import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/widgets/detail_chip.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _item = MenuItem(
  id: 2,
  name: 'Cola',
  description: 'Bebida fría',
  price: 1.60,
  originalPrice: 2.00,
  discountPercentage: 20,
  category: 'Bebidas',
  ingredients: [Ingredient(id: 1, name: 'Azúcar')],
  allergens: [Allergen(id: 3, name: 'Cafeína')],
  stock: 10,
);

Future<void> _pump(WidgetTester tester, {ValueChanged<int>? onAdd}) async {
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
                builder: (_) => ProductDetailScreen(item: _item, onAdd: onAdd),
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
  testWidgets('shows the name, both prices, ingredients and allergens', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Cola'), findsOneWidget);
    expect(find.text('Bebida fría'), findsOneWidget);
    expect(find.text('\$2.00'), findsOneWidget);
    expect(find.text('\$1.60'), findsOneWidget);
    expect(find.text('Ingredientes'), findsOneWidget);
    expect(find.text('Azúcar'), findsOneWidget);
    expect(find.text('Contiene alérgenos'), findsOneWidget);
    expect(find.text('Cafeína'), findsOneWidget);
    expect(find.byType(DetailChip), findsNWidgets(2));
  });

  testWidgets('is read-only without onAdd', (tester) async {
    await _pump(tester);

    expect(find.byType(QuantityAddBar), findsNothing);
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
