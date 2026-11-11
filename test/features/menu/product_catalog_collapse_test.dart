import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
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

Finder get _scroll => find.byType(CustomScrollView);

double _scrolled(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

Future<void> _scrollDown(WidgetTester tester, [double by = 900]) async {
  await tester.drag(_scroll, Offset(0, -by));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts with the full header visible', (tester) async {
    await _pump(tester);

    // The header measures itself with invisible copies, so only look at the
    // painted (hit-testable) widgets.
    expect(find.text('Productos').hitTestable(), findsWidgets);
    expect(find.text('selector menu-productos').hitTestable(), findsOneWidget);
    expect(find.text('banner del hijo').hitTestable(), findsOneWidget);
    expect(find.byType(CategoryFilterBar).hitTestable(), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
  });

  testWidgets('scrolling down folds title, selector, banner and categories', (
    tester,
  ) async {
    await _pump(tester);

    await _scrollDown(tester);

    expect(find.byType(CategoryFilterBar).hitTestable(), findsNothing);
    expect(find.text('selector menu-productos').hitTestable(), findsNothing);
    expect(find.text('banner del hijo').hitTestable(), findsNothing);
    // The search field stays, pinned at the top of the screen.
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
  });

  testWidgets('the products get the space the header gave up', (tester) async {
    await _pump(tester);
    final firstBefore = tester.getTopLeft(find.text('Producto 1').first).dy;

    await _scrollDown(tester, 300);
    // After folding the header the first visible product sits right under
    // the search field, much higher than it was with the full header.
    final visible = find.textContaining('Producto ').hitTestable();
    final topVisible = tester.getTopLeft(visible.first).dy;

    expect(topVisible, lessThan(firstBefore));
    expect(topVisible, lessThan(140));
  });

  testWidgets('the list follows the scroll 1 to 1 (no timed animation)', (
    tester,
  ) async {
    await _pump(tester);
    final startTop = tester.getTopLeft(find.text('Producto 1')).dy;
    final gesture = await tester.startGesture(const Offset(180, 450));

    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(); // one frame: no time for any animation to run
      final scroll = _scrolled(tester);
      if (scroll == 0) continue;
      final top = tester.getTopLeft(find.text('Producto 1')).dy;
      // While the header shrinks, the first product rises exactly by what was
      // scrolled: the header takes no extra time or distance.
      expect(startTop - top, closeTo(scroll, 0.5));
    }
    await gesture.up();
  });

  testWidgets('the search keeps working with the header folded', (
    tester,
  ) async {
    await _pump(tester);
    await _scrollDown(tester);

    await tester.enterText(find.byType(TextField).hitTestable(), 'Producto 7');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Producto 7'), findsWidgets);
    expect(find.text('Producto 8'), findsNothing);
  });

  testWidgets('the whole header returns when the list is back at the top', (
    tester,
  ) async {
    await _pump(tester);
    await _scrollDown(tester);

    await tester.drag(_scroll, const Offset(0, 3000));
    await tester.pumpAndSettle();

    expect(find.text('selector menu-productos').hitTestable(), findsOneWidget);
    expect(find.byType(CategoryFilterBar).hitTestable(), findsOneWidget);
  });

  testWidgets('tapping a combo opens its detail, read-only', (tester) async {
    await _pump(tester, offers: _offers);

    await tester.tap(find.text('Combo almuerzo'));
    await tester.pumpAndSettle();

    expect(find.byType(ComboDetailScreen), findsOneWidget);
    expect(find.text('Incluye'), findsOneWidget);
    expect(find.textContaining('Añadir'), findsNothing);
  });
}
