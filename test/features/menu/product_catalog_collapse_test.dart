import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/widgets/category_filter_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

/// Enough products (two categories) to make the list scroll on a phone.
final _items = [
  for (var i = 1; i <= 25; i++)
    product(
      i,
      'Producto $i',
      1.0 + i / 10,
      category: i.isEven ? 'Bebidas' : 'Snacks',
    ),
];

final _offers = CatalogOffers(
  combos: [
    lunchCombo(
      items: const [
        ComboItem(productId: 1, name: 'Producto 1', quantity: 1),
        ComboItem(productId: 2, name: 'Producto 2', quantity: 1),
      ],
    ),
  ],
  promotions: [
    Promotion(
      id: 3,
      discountPercentage: 20,
      endDate: DateTime(2026, 12, 31),
      productNames: const ['Producto 4'],
      productIds: const [4],
    ),
  ],
);

Future<void> _pump(WidgetTester tester, {CatalogOffers? offers}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ProductCatalogView(
        title: 'Productos',
        headerAccessory: const Text('selector menu-productos'),
        banner: const Text('banner del hijo'),
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

Finder get _list => find.byType(RefreshIndicator);

void main() {
  testWidgets('starts with the full header visible', (tester) async {
    await _pump(tester);

    expect(find.text('Productos'), findsWidgets);
    expect(find.text('selector menu-productos'), findsOneWidget);
    expect(find.text('banner del hijo'), findsOneWidget);
    expect(find.byType(CategoryFilterBar), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('scrolling down folds title, selector, banner and categories', (
    tester,
  ) async {
    await _pump(tester);
    final before = tester.getSize(_list).height;

    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Folded: clipped to zero height, so nothing of it can be reached.
    expect(find.byType(CategoryFilterBar).hitTestable(), findsNothing);
    expect(find.text('selector menu-productos').hitTestable(), findsNothing);
    expect(find.text('banner del hijo').hitTestable(), findsNothing);
    expect(tester.getSize(_list).height, greaterThan(before + 100));
  });

  testWidgets('the search field stays while the rest is folded', (
    tester,
  ) async {
    await _pump(tester);

    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Producto 7');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Producto 7'), findsWidgets);
    expect(find.text('Producto 8'), findsNothing);
  });

  testWidgets('scrolling back up shows everything again', (tester) async {
    await _pump(tester);
    final before = tester.getSize(_list).height;
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(find.text('selector menu-productos'), findsOneWidget);
    expect(tester.getSize(_list).height, before);
  });

  testWidgets('tapping a combo opens its detail, read-only', (tester) async {
    await _pump(tester, offers: _offers);

    await tester.tap(find.text('Combo almuerzo'));
    await tester.pumpAndSettle();

    expect(find.byType(ComboDetailScreen), findsOneWidget);
    expect(find.text('Incluye'), findsOneWidget);
    expect(find.textContaining('Añadir'), findsNothing);
  });

  testWidgets('tapping a product of a discount opens its normal detail', (
    tester,
  ) async {
    await _pump(tester, offers: _offers);

    // "Producto 4" is also in the list below; the first one is in the offer.
    final inOffer = find.text('Producto 4').first;
    await tester.ensureVisible(inOffer);
    await tester.pumpAndSettle();
    await tester.tap(inOffer);
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });
}
