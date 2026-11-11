import 'package:delycattessen_flutter/core/widgets/collapsing_header.dart';
import 'package:delycattessen_flutter/core/widgets/collapsing_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _keptKey = Key('kept');
const _collapsibleKey = Key('collapsible');

const _keptHeight = 50.0;
const _collapsibleHeight = 120.0;

/// Scroll distance the header needs to fold completely.
const _fold = _collapsibleHeight;

const _rowHeight = 60.0;

Widget _app({
  int rows = 3,
  int? itemCount,
  double rowHeight = _rowHeight,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: CollapsingScrollView(
      itemCount: itemCount ?? rows,
      header: const CollapsingHeader(
        kept: SizedBox(key: _keptKey, height: _keptHeight, child: Text('fijo')),
        collapsible: SizedBox(
          key: _collapsibleKey,
          height: _collapsibleHeight,
          child: Text('colapsable'),
        ),
      ),
      slivers: [
        SliverList.builder(
          itemCount: rows,
          itemBuilder: (_, i) =>
              SizedBox(height: rowHeight, child: Text('fila $i')),
        ),
      ],
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

double _scrolled(WidgetTester tester) => _position(tester).pixels;

/// The header measures with invisible prototypes that carry the same keys;
/// only the painted (hit-testable) one is the real one.
Finder _real(Key key) => find.byKey(key).hitTestable();

Future<void> _drag(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(CustomScrollView), Offset(0, dy));
  await tester.pumpAndSettle();
}

void main() {
  group('short list (3 items)', () {
    testWidgets('scrolling folds the header completely', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pump();

      await _drag(tester, -600);

      expect(tester.takeException(), isNull);
      expect(_scrolled(tester), _fold);
      expect(tester.getTopLeft(_real(_keptKey)).dy, 0);
      expect(_real(_collapsibleKey), findsNothing);
    });

    testWidgets('it has at least the fold distance to scroll', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pump();

      expect(_position(tester).maxScrollExtent, greaterThanOrEqualTo(_fold));
    });

    testWidgets('the whole header is back when the list returns to the top', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pump();
      await _drag(tester, -600);

      await _drag(tester, 600);

      expect(_scrolled(tester), 0);
      expect(_real(_collapsibleKey), findsOneWidget);
    });
  });

  group('no scroll needed (0 or 1 item)', () {
    for (final count in [0, 1]) {
      testWidgets('$count item(s): no scroll, the header stays whole', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(_app(rows: count));
        await tester.pump();

        await _drag(tester, -600);

        expect(tester.takeException(), isNull);
        expect(_scrolled(tester), 0);
        expect(_position(tester).maxScrollExtent, 0);
        expect(_real(_collapsibleKey), findsOneWidget);
        expect(_real(_keptKey), findsOneWidget);
      });
    }

    testWidgets('one item taller than the screen still folds the header', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app(rows: 1, rowHeight: 900));
      await tester.pump();

      await _drag(tester, -600);

      expect(_scrolled(tester), greaterThanOrEqualTo(_fold));
      expect(_real(_collapsibleKey), findsNothing);
    });

    testWidgets('a custom minItemsToFold of 1 folds a single item', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsingScrollView(
              itemCount: 1,
              minItemsToFold: 1,
              header: const CollapsingHeader(
                kept: SizedBox(key: _keptKey, height: _keptHeight),
                collapsible: SizedBox(
                  key: _collapsibleKey,
                  height: _collapsibleHeight,
                ),
              ),
              slivers: const [
                SliverToBoxAdapter(child: SizedBox(height: _rowHeight)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await _drag(tester, -600);

      expect(_scrolled(tester), _fold);
    });
  });

  group('snap when the finger lifts', () {
    testWidgets('less than half way goes back to the start', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pump();

      await _drag(tester, -40);

      expect(_scrolled(tester), 0);
      expect(_real(_collapsibleKey), findsOneWidget);
    });

    testWidgets('more than half way goes on to fold completely', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pump();

      await _drag(tester, -100);

      expect(_scrolled(tester), _fold);
      expect(_real(_collapsibleKey), findsNothing);
    });

    testWidgets('the header follows the finger 1 to 1 while dragging', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pump();
      final gesture = await tester.startGesture(const Offset(180, 400));

      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();

      // Still held: no snap yet, the scroll sits between the two ends.
      expect(_scrolled(tester), inExclusiveRange(0, _fold));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a list that already overflows also snaps', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(rows: 40));
      await tester.pump();

      await _drag(tester, -40);

      expect(_scrolled(tester), 0);
    });
  });

  group('the content changes', () {
    testWidgets('going from 3 items to 1 expands the header again', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pump();
      await _drag(tester, -600);
      expect(_real(_collapsibleKey), findsNothing);

      await tester.pumpWidget(_app(rows: 1));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_scrolled(tester), 0);
      expect(_real(_collapsibleKey), findsOneWidget);
    });

    testWidgets('going from 1 item to 3 lets the header fold', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(rows: 1));
      await tester.pump();

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _drag(tester, -600);

      expect(_real(_collapsibleKey), findsNothing);
    });

    testWidgets('loading or error (itemCount 0) adds no extra scroll', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app(rows: 3, itemCount: 0));
      await tester.pump();

      expect(_position(tester).maxScrollExtent, 0);
    });
  });

  testWidgets('works with text at 200 % without exceptions', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(textScale: 2));
    await tester.pump();

    await _drag(tester, -600);
    await _drag(tester, 600);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a header with no CollapsingScrollView keeps working alone', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              CollapsingHeader(
                kept: SizedBox(
                  key: _keptKey,
                  height: _keptHeight,
                  child: Text('fijo'),
                ),
                collapsible: SizedBox(
                  key: _collapsibleKey,
                  height: _collapsibleHeight,
                  child: Text('colapsable'),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(_real(_collapsibleKey), findsOneWidget);
  });
}
