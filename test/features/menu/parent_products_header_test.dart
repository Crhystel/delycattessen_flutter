import 'package:delycattessen_flutter/core/widgets/floating_bubbles.dart';
import 'package:delycattessen_flutter/features/menu/widgets/category_filter_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

final _items = [
  for (var i = 1; i <= 25; i++)
    product(
      i,
      'Producto $i',
      1.0 + i / 10,
      category: i.isEven ? 'Bebidas' : 'Snacks',
    ),
];

/// The parent view, with a status bar of [topInset] dp like a phone with a
/// camera cut-out.
Future<void> _pump(WidgetTester tester, {double topInset = 0}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(top: topInset),
          viewPadding: EdgeInsets.only(top: topInset),
        ),
        child: child!,
      ),
      home: ProductCatalogView(
        title: 'Menú',
        headerAccessory: const Text('selector menu-productos'),
        categoryStyle: CategoryFilterStyle.evenCircles,
        flatLayout: true,
        source: FakeCatalogSource(items: _items),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _shown(Finder finder) => finder.hitTestable();

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(_shown(finder)).dy;

void main() {
  testWidgets('the header goes title, selector, search, categories', (
    tester,
  ) async {
    await _pump(tester);

    final title = _top(tester, find.text('Menú'));
    final selector = _top(tester, find.text('selector menu-productos'));
    final search = _top(tester, find.byType(TextField));
    final categories = _top(tester, find.byType(CategoryFilterBar));

    expect(title, lessThan(selector));
    expect(selector, lessThan(search));
    expect(search, lessThan(categories));
  });

  testWidgets('title, selector and categories fold; only the search stays', (
    tester,
  ) async {
    await _pump(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(_shown(find.text('Menú')), findsNothing);
    expect(_shown(find.text('selector menu-productos')), findsNothing);
    expect(_shown(find.byType(CategoryFilterBar)), findsNothing);
    expect(_shown(find.byType(TextField)), findsOneWidget);
  });

  testWidgets('everything comes back when the list returns to its start', (
    tester,
  ) async {
    await _pump(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1500));
    await tester.pumpAndSettle();

    expect(_shown(find.text('Menú')), findsOneWidget);
    expect(_shown(find.text('selector menu-productos')), findsOneWidget);
    expect(_shown(find.byType(CategoryFilterBar)), findsOneWidget);
  });

  testWidgets('folded, the search sits right under the status bar and the '
      'bubbles stay behind it', (tester) async {
    await _pump(tester, topInset: 30);
    final expandedSearchTop = _top(tester, find.byType(TextField));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    final foldedSearchTop = _top(tester, find.byType(TextField));
    // Pinned just below the inset, much higher than when expanded.
    expect(foldedSearchTop, greaterThanOrEqualTo(30));
    expect(foldedSearchTop, lessThan(expandedSearchTop));
    expect(foldedSearchTop, lessThan(80));
    // The page's own bubbles plus the copy behind the opaque pinned band.
    expect(find.byType(FloatingBubbles), findsNWidgets(2));
  });

  testWidgets('folded, the pinned part stays below the status bar', (
    tester,
  ) async {
    await _pump(tester, topInset: 30);
    // Expanded: the title is a fixed margin under the status bar.
    expect(_top(tester, find.text('Menú')), greaterThanOrEqualTo(30));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(_top(tester, find.byType(TextField)), greaterThanOrEqualTo(30));
  });

  testWidgets('the search clear button follows the text', (tester) async {
    await _pump(tester);

    expect(find.byIcon(Icons.close), findsNothing);
    await tester.enterText(_shown(find.byType(TextField)), 'cola');
    await tester.pump();

    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
