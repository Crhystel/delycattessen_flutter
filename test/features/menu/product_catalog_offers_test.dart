import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/widgets/offers_section.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

final _items = [
  product(1, 'Sánduche', 2.50),
  product(2, 'Cola', 1.60, category: 'Bebidas'),
  // Enough products to make the page scroll past the offers.
  for (var i = 3; i <= 25; i++) product(i, 'Producto $i', 1.0 + i / 10),
];

final _offers = CatalogOffers(combos: [lunchCombo()]);

Future<void> _pump(WidgetTester tester, {CatalogOffers? offers}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ProductCatalogView(
        source: FakeCatalogSource(
          items: _items,
          offers: offers ?? CatalogOffers.empty,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows the combo with its dishes and the two prices', (
    tester,
  ) async {
    await _pump(tester, offers: _offers);

    expect(find.byType(OffersSection), findsOneWidget);
    expect(find.text('Combo almuerzo'), findsOneWidget);
    expect(find.text('Ahorras \$0.50'), findsOneWidget);
    expect(find.text('Cómpralo en caja'), findsOneWidget);
    expect(find.text('Agregar combo'), findsNothing);
  });

  testWidgets('offers scroll with the list instead of taking fixed space', (
    tester,
  ) async {
    await _pump(tester, offers: _offers);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    // Past the offers the products have the screen for themselves.
    expect(find.byType(OffersSection).hitTestable(), findsNothing);
    expect(find.textContaining('Producto ').hitTestable(), findsWidgets);
  });

  testWidgets('the products are reachable below the offers', (tester) async {
    await _pump(tester, offers: _offers);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();

    expect(find.text('Producto 25'), findsOneWidget);
  });

  testWidgets('offers hide while searching', (tester) async {
    await _pump(tester, offers: _offers);

    await tester.enterText(find.byType(TextField).hitTestable(), 'sán');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OffersSection), findsNothing);
    expect(find.text('Sánduche'), findsOneWidget);
  });

  testWidgets('offers hide when a category is chosen', (tester) async {
    await _pump(tester, offers: _offers);

    await tester.tap(find.text('Bebidas').first);
    await tester.pump();

    expect(find.byType(OffersSection), findsNothing);
  });

  testWidgets('without offers there is no offers section', (tester) async {
    await _pump(tester);

    expect(find.byType(OffersSection), findsNothing);
    expect(find.text('Sánduche'), findsOneWidget);
  });
}
