import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<Combo> _combos() => [
  for (var id = 1; id <= 3; id++)
    Combo(
      id: id,
      name: 'Combo $id',
      price: 2,
      regularPrice: 7,
      endDate: DateTime(2026, 11, 12),
    ),
];

Widget _host(Widget carousel, {bool tickers = true}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: TickerMode(enabled: tickers, child: carousel),
    ),
  ),
);

/// Replaces the tree so the carousel's periodic timer is cancelled.
Future<void> _unmount(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

void main() {
  const autoAdvance = Duration(seconds: 1);

  testWidgets('a hidden tab (tickers off) does not advance the carousel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        ComboCarousel(combos: _combos(), autoAdvance: autoAdvance),
        tickers: false,
      ),
    );

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('1 de 3'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('it starts advancing when the tab becomes visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final combos = _combos();
    await tester.pumpWidget(
      _host(
        ComboCarousel(combos: combos, autoAdvance: autoAdvance),
        tickers: false,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('1 de 3'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        ComboCarousel(combos: combos, autoAdvance: autoAdvance),
        tickers: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.text('2 de 3'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a rebuild with the same combos does not reset the timer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(ComboCarousel(combos: _combos(), autoAdvance: autoAdvance)),
    );

    await tester.pump(const Duration(milliseconds: 600));
    // The parent rebuilds (new list instance, same combos).
    await tester.pumpWidget(
      _host(ComboCarousel(combos: _combos(), autoAdvance: autoAdvance)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // 1100 ms after the start: the first tick was not postponed.
    expect(find.text('2 de 3'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a single combo takes the same 86 % of the width as many', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(ComboCarousel(combos: [_combos().first])));

    final card = find.ancestor(
      of: find.text('Combo 1'),
      matching: find.byType(SizedBox),
    );
    final widths = card.evaluate().map((e) => e.size!.width).toSet();

    // The page content is 390 wide here: 86 % = 335.4.
    expect(widths.any((w) => (w - 390 * 0.86).abs() < 0.5), isTrue);
    await _unmount(tester);
  });
}
