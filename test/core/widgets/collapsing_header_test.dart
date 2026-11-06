import 'package:delycattessen_flutter/core/widgets/collapsing_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _keptKey = Key('kept');
const _collapsibleKey = Key('collapsible');
const _firstRowKey = Key('first-row');

const _keptHeight = 50.0;
const _collapsibleHeight = 120.0;
const _fullHeight = _keptHeight + _collapsibleHeight;

Widget _app({
  CollapsingHeaderKeep keep = CollapsingHeaderKeep.top,
  int rows = 40,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: CustomScrollView(
      slivers: [
        CollapsingHeader(
          keep: keep,
          kept: const SizedBox(
            key: _keptKey,
            height: _keptHeight,
            child: Text('fijo'),
          ),
          collapsible: const SizedBox(
            key: _collapsibleKey,
            height: _collapsibleHeight,
            child: Text('colapsable'),
          ),
        ),
        SliverList.builder(
          itemCount: rows,
          itemBuilder: (_, i) => SizedBox(
            key: i == 0 ? _firstRowKey : null,
            height: 60,
            child: Text('fila $i'),
          ),
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

double _scrolled(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

/// The header measures its parts with invisible prototypes that carry the same
/// keys; only the painted (hit-testable) one is the real one.
Finder _real(Key key) => find.byKey(key).hitTestable();

double _top(WidgetTester tester, Key key) {
  // The rows are not duplicated by the header, and may sit under the pinned
  // header (not hit-testable) while the list scrolls.
  final finder = key == _firstRowKey
      ? find.byKey(key)
      : find.byKey(key).hitTestable();
  return tester.getTopLeft(finder).dy;
}

void main() {
  for (final keep in CollapsingHeaderKeep.values) {
    group('keep ${keep.name}', () {
      testWidgets('starts with the whole header visible', (tester) async {
        _phone(tester);
        await tester.pumpWidget(_app(keep: keep));

        expect(_top(tester, _firstRowKey), _fullHeight);
        expect(_real(_collapsibleKey), findsOneWidget);
        expect(_real(_keptKey), findsOneWidget);
      });

      testWidgets('the list moves exactly as much as the finger (1 to 1)', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(_app(keep: keep));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -40));
        await tester.pump();

        // Header shrinks by what was scrolled: the first row follows the
        // scroll position exactly (not twice as fast, not delayed).
        expect(_scrolled(tester), greaterThan(0));
        expect(_top(tester, _firstRowKey), _fullHeight - _scrolled(tester));
      });

      testWidgets('it follows the scroll at every step, with no animation', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(_app(keep: keep));
        final gesture = await tester.startGesture(const Offset(180, 400));

        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(const Offset(0, -15));
          await tester.pump(); // a single frame, no time passes
          expect(
            _top(tester, _firstRowKey),
            closeTo(
              (_fullHeight - _scrolled(tester)).clamp(0, _fullHeight),
              0.01,
            ),
          );
        }
        await gesture.up();
      });

      testWidgets('after scrolling past it only the kept part is left', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(_app(keep: keep));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();

        expect(_top(tester, _keptKey), 0); // pinned at the very top
        expect(tester.getSize(_real(_keptKey)).height, _keptHeight);
        expect(_real(_keptKey), findsOneWidget);
        expect(_real(_collapsibleKey), findsNothing);
      });

      testWidgets('the whole header is back when the list returns to the top', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(_app(keep: keep));
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(CustomScrollView), const Offset(0, 1500));
        await tester.pumpAndSettle();

        expect(_scrolled(tester), 0);
        expect(_top(tester, _firstRowKey), _fullHeight);
        expect(_real(_collapsibleKey), findsOneWidget);
      });

      testWidgets('keeps the kept part visible with the text at 200 %', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(_app(keep: keep, textScale: 2));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_top(tester, _keptKey), 0);
      });
    });
  }

  testWidgets('keep top: the kept part is at the top while expanded', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());

    expect(_top(tester, _keptKey), 0);
    expect(_top(tester, _collapsibleKey), _keptHeight);
  });

  testWidgets('keep bottom: the kept part is under the collapsible one', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(keep: CollapsingHeaderKeep.bottom));

    expect(_top(tester, _collapsibleKey), 0);
    expect(_top(tester, _keptKey), _collapsibleHeight);
  });

  testWidgets('the measuring prototypes are hidden from accessibility', (
    tester,
  ) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());

    // Only one "fijo" and one "colapsable" reach the semantics tree.
    expect(find.bySemanticsLabel('fijo'), findsOneWidget);
    expect(find.bySemanticsLabel('colapsable'), findsOneWidget);
    handle.dispose();
  });
}
