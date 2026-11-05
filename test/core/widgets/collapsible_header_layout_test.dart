import 'package:delycattessen_flutter/core/widgets/collapsible_header_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _headerKey = Key('collapsible');
const _pinnedKey = Key('pinned');

Widget _layout({int rows = 40}) => MaterialApp(
  home: Scaffold(
    body: CollapsibleHeaderLayout(
      pinned: const SizedBox(key: _pinnedKey, height: 50, child: Text('fijo')),
      collapsible: const SizedBox(
        key: _headerKey,
        height: 120,
        child: Text('colapsable'),
      ),
      body: ListView.builder(
        itemCount: rows,
        itemBuilder: (_, i) => SizedBox(height: 60, child: Text('fila $i')),
      ),
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

double _headerHeight(WidgetTester tester) =>
    tester.getSize(find.byType(ClipRect).first).height;

void main() {
  testWidgets('the header is visible at the start', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_layout());

    expect(_headerHeight(tester), 120);
    expect(find.text('colapsable'), findsOneWidget);
  });

  testWidgets('dragging the list down folds the header and frees space', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_layout());
    final listBefore = tester.getSize(find.byType(ListView)).height;

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(_headerHeight(tester), 0);
    expect(tester.getSize(find.byType(ListView)).height, listBefore + 120);
  });

  testWidgets('dragging back up brings the header back', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_layout());
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(_headerHeight(tester), 120);
  });

  testWidgets('the pinned part never hides', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_layout());
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byKey(_pinnedKey), findsOneWidget);
    expect(tester.getSize(find.byKey(_pinnedKey)).height, 50);
  });

  testWidgets('the header returns when the list is back at the top', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_layout());
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_headerHeight(tester), 0);

    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();

    expect(_headerHeight(tester), 120);
  });

  testWidgets('does not fold when the list would stop being scrollable', (
    tester,
  ) async {
    _phone(tester);
    // 8 rows of 60 dp: scrollable, but only by a little (less than the header).
    await tester.pumpWidget(_layout(rows: 8));

    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(_headerHeight(tester), 120);
  });

  testWidgets('a programmatic jump does not fold the header', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_layout());

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(400);
    await tester.pumpAndSettle();

    expect(_headerHeight(tester), 120);
  });
}
