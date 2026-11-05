import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/widgets/offers_section.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

final _items = [
  product(1, 'Sánduche', 2.50),
  product(
    2,
    'Cola',
    1.60,
    originalPrice: 2.00,
    discount: 20,
    category: 'Bebidas',
  ),
];

final _offers = CatalogOffers(
  combos: [lunchCombo()],
  promotions: [colaPromotion()],
);

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
  testWidgets('shows the offers with the dishes and the two prices', (
    tester,
  ) async {
    await _pump(tester, offers: _offers);

    expect(find.byType(OffersSection), findsOneWidget);
    expect(find.text('Combo almuerzo'), findsOneWidget);
    expect(find.text('Ahorras \$0.50'), findsOneWidget);
    expect(find.text('Cómpralo en caja'), findsOneWidget);
    expect(find.text('Agregar combo'), findsNothing);
  });

  testWidgets('offers do not shrink the list of products', (tester) async {
    await _pump(tester);
    final without = tester.getSize(find.byType(RefreshIndicator)).height;

    await _pump(tester, offers: _offers);
    final withOffers = tester.getSize(find.byType(RefreshIndicator)).height;

    // The old fixed banner took ~160 dp from the list; now it scrolls inside.
    expect(withOffers, without);
    expect(withOffers, greaterThan(640 * 0.4));
  });

  testWidgets('the products are still reachable below the offers', (
    tester,
  ) async {
    await _pump(tester, offers: _offers);

    await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
    await tester.pump();

    expect(find.text('Sánduche'), findsWidgets);
    expect(find.text('Cola'), findsWidgets);
  });

  testWidgets('offers hide while searching', (tester) async {
    await _pump(tester, offers: _offers);

    await tester.enterText(find.byType(TextField), 'sán');
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
