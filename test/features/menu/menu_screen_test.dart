import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/menu_screen_test_support.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool embedded = true,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    menuScreenApp(embedded: embedded, textScale: textScale),
  );
  await settleMenu(tester);
}

Finder get _scroll => find.byType(CustomScrollView);

/// The header measures itself with invisible copies: look at painted widgets.
Finder _shown(Finder finder) => finder.hitTestable();

Future<void> _scrollDown(WidgetTester tester) async {
  await tester.drag(_scroll, const Offset(0, -900));
  await tester.pump(
    const Duration(seconds: 2),
  ); // the bubbles animate forever: no pumpAndSettle
}

void main() {
  testWidgets('shows title, selector, banner, search, days and the dishes', (
    tester,
  ) async {
    await _pump(tester);

    expect(_shown(find.text('Menú')), findsOneWidget);
    expect(_shown(find.text('selector menu-productos')), findsOneWidget);
    expect(_shown(find.text('Pidiendo para')), findsOneWidget);
    expect(_shown(find.byType(TextField)), findsOneWidget);
    expect(_shown(find.text('2')), findsOneWidget); // first day, selected
    expect(_shown(find.text('Plato 1 del día 2')), findsOneWidget);
    // The old label is gone: only the days and the search stay.
    expect(find.text('Días disponibles'), findsNothing);
  });

  testWidgets('scrolling folds title, selector and banner', (tester) async {
    await _pump(tester);

    await _scrollDown(tester);

    expect(_shown(find.text('Menú')), findsNothing);
    expect(_shown(find.text('selector menu-productos')), findsNothing);
    expect(_shown(find.text('Pidiendo para')), findsNothing);
  });

  testWidgets('only the days and the search bar stay while scrolling', (
    tester,
  ) async {
    await _pump(tester);

    await _scrollDown(tester);

    expect(_shown(find.byType(TextField)), findsOneWidget);
    expect(_shown(find.text('2')), findsOneWidget);
    expect(_shown(find.text('3')), findsOneWidget);
    expect(_shown(find.text('6')), findsOneWidget);
    // The search bar is pinned right at the top of the screen.
    expect(tester.getTopLeft(_shown(find.byType(TextField))).dy, lessThan(80));
  });

  testWidgets('the days still select a day while the header is folded', (
    tester,
  ) async {
    await _pump(tester);
    await _scrollDown(tester);

    await tester.tap(_shown(find.text('3')));
    await tester.pump(
      const Duration(seconds: 2),
    ); // the bubbles animate forever: no pumpAndSettle

    expect(find.text('Plato 1 del día 3'), findsOneWidget);
    expect(find.text('Plato 1 del día 2'), findsNothing);
  });

  testWidgets('a blocked day shows a lock and does not open', (tester) async {
    await _pump(tester);

    expect(_shown(find.byIcon(Icons.lock_outline)), findsOneWidget);
    await tester.tap(_shown(find.byIcon(Icons.lock_outline)));
    await tester.pump();

    expect(find.text('Plato 1 del día 2'), findsOneWidget);
    expect(find.text('Plato 1 del día 4'), findsNothing);
  });

  testWidgets('the search filters the dishes and works folded', (tester) async {
    await _pump(tester);
    await _scrollDown(tester);

    await tester.enterText(_shown(find.byType(TextField)), 'Plato 7');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(
      const Duration(seconds: 2),
    ); // the bubbles animate forever: no pumpAndSettle

    expect(find.text('Plato 7 del día 2'), findsOneWidget);
    expect(find.text('Plato 8 del día 2'), findsNothing);
  });

  testWidgets('the whole header returns when the list is back at the top', (
    tester,
  ) async {
    await _pump(tester);
    await _scrollDown(tester);

    await tester.drag(_scroll, const Offset(0, 3000));
    await tester.pump(
      const Duration(seconds: 2),
    ); // the bubbles animate forever: no pumpAndSettle

    expect(_shown(find.text('Menú')), findsOneWidget);
    expect(_shown(find.text('selector menu-productos')), findsOneWidget);
    expect(_shown(find.text('Pidiendo para')), findsOneWidget);
  });

  testWidgets('has no back arrow when embedded in the shell', (tester) async {
    await _pump(tester);

    expect(find.byTooltip('Volver'), findsNothing);
  });

  testWidgets('shows a back arrow in the search row when it is a page', (
    tester,
  ) async {
    await _pump(tester, embedded: false);
    await _scrollDown(tester);

    // The arrow lives next to the search, so it stays when the rest folds.
    expect(_shown(find.byTooltip('Volver')), findsOneWidget);
  });

  testWidgets('keeps working with the text at 200 %', (tester) async {
    await _pump(tester, textScale: 2);
    await _scrollDown(tester);

    expect(tester.takeException(), isNull);
    expect(_shown(find.byType(TextField)), findsOneWidget);
  });
}
