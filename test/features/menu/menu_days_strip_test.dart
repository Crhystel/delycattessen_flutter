import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/widgets/menu_days_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MenuDay _day(int id, {bool blocked = false}) => MenuDay(
  id: id,
  date: '2026-11-0$id',
  isBlockedByParentalControl: blocked,
  dishes: const [],
);

Widget _host({
  required List<MenuDay> days,
  int? selected,
  ValueChanged<MenuDay>? onSelect,
  bool design = false,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: MenuDaysStrip(
      days: days,
      selectedDayId: selected,
      onSelect: onSelect ?? (_) {},
      design: design,
    ),
  ),
);

void _setWidth(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<MenuDay> _days(int count) => [for (var d = 1; d <= count; d++) _day(d)];

/// Rect of the chip that shows [dayNumber] (the tappable container).
Rect _chipRect(WidgetTester tester, int dayNumber) => tester.getRect(
  find
      .ancestor(
        of: find.text('$dayNumber'),
        matching: find.byType(GestureDetector),
      )
      .first,
);

/// Area where the strip paints: whatever leaves it is clipped. The outermost
/// ClipRect is the strip's own (the scrollable adds another one inside).
Rect _clipRect(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(MenuDaysStrip),
        matching: find.byType(ClipRect),
      )
      .first,
);

double _maxScrollExtent(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable))
    .position
    .maxScrollExtent;

void main() {
  testWidgets('shows the number and weekday of every day', (tester) async {
    await tester.pumpWidget(_host(days: [_day(2), _day(3)], selected: 2));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // 2 and 3 November 2026 are Monday and Tuesday.
    expect(find.text('Lun'), findsOneWidget);
    expect(find.text('Mar'), findsOneWidget);
  });

  testWidgets('selecting a day reports it', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(
      _host(
        days: [_day(2), _day(3)],
        selected: 2,
        onSelect: (d) => picked.add(d.id),
      ),
    );

    await tester.tap(find.text('3'));

    expect(picked, [3]);
  });

  testWidgets('a blocked day shows a lock instead of the number', (
    tester,
  ) async {
    await tester.pumpWidget(_host(days: [_day(2), _day(4, blocked: true)]));

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('many days scroll sideways without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(days: [for (var d = 1; d <= 9; d++) _day(d)], selected: 1),
    );

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(MenuDaysStrip), const Offset(-600, 0));
    await tester.pump();
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('takes the height its content needs with a large font', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: MenuDaysStrip(
            days: [_day(2), _day(3)],
            selectedDayId: 2,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  group('design margins', () {
    const page = 20.0;

    testWidgets('chips are clipped 20 px from the screen edges', (
      tester,
    ) async {
      _setWidth(tester, 340);
      await tester.pumpWidget(_host(days: _days(9), selected: 1, design: true));

      final clip = _clipRect(tester);
      expect(clip.left, page);
      expect(clip.right, 340 - page);
      expect(_chipRect(tester, 1).left, page);

      await tester.drag(find.byType(MenuDaysStrip), const Offset(-1000, 0));
      await tester.pumpAndSettle();

      expect(_chipRect(tester, 9).right, closeTo(340 - page, 0.01));
      // Everything that sticks out of the strip is cut by the ClipRect, which
      // never reaches the physical edge.
      expect(clip.left, greaterThan(0));
      expect(clip.right, lessThan(340));
    });

    for (final width in [320.0, 340.0, 360.0, 390.0]) {
      testWidgets('six days fit without scrolling at ${width.toInt()} px', (
        tester,
      ) async {
        _setWidth(tester, width);
        await tester.pumpWidget(
          _host(days: _days(6), selected: 1, design: true),
        );

        expect(tester.takeException(), isNull);
        expect(_maxScrollExtent(tester), closeTo(0, 0.001));
        for (var d = 1; d <= 6; d++) {
          final rect = _chipRect(tester, d);
          expect(rect.left, greaterThanOrEqualTo(page - 0.01));
          expect(rect.right, lessThanOrEqualTo(width - page + 0.01));
        }
      });
    }

    testWidgets('the last selected day is visible once it settles', (
      tester,
    ) async {
      _setWidth(tester, 360);
      await tester.pumpWidget(_host(days: _days(9), selected: 9, design: true));
      await tester.pumpAndSettle();

      final clip = _clipRect(tester);
      final chip = _chipRect(tester, 9);
      expect(chip.left, greaterThanOrEqualTo(clip.left));
      expect(chip.right, closeTo(clip.right, 0.01));
    });

    testWidgets('a day in the middle is centered', (tester) async {
      _setWidth(tester, 360);
      await tester.pumpWidget(_host(days: _days(9), selected: 5, design: true));
      await tester.pumpAndSettle();

      expect(_chipRect(tester, 5).center.dx, closeTo(360 / 2, 0.01));
    });

    testWidgets('changing the selected day brings the new chip into view', (
      tester,
    ) async {
      _setWidth(tester, 360);
      await tester.pumpWidget(_host(days: _days(9), selected: 1, design: true));
      await tester.pumpAndSettle();
      expect(_chipRect(tester, 1).left, page);

      await tester.pumpWidget(_host(days: _days(9), selected: 9, design: true));
      await tester.pumpAndSettle();

      final clip = _clipRect(tester);
      final chip = _chipRect(tester, 9);
      expect(chip.left, greaterThanOrEqualTo(clip.left));
      expect(chip.right, lessThanOrEqualTo(clip.right + 0.01));
    });

    testWidgets('without design the strip keeps its inner padding and does '
        'not recenter', (tester) async {
      _setWidth(tester, 360);
      await tester.pumpWidget(_host(days: _days(9), selected: 9));
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        0,
      );
      expect(_chipRect(tester, 1).left, 16);
    });

    for (final width in [320.0, 340.0, 390.0, 768.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('does not overflow at ${width.toInt()} px, text x$scale', (
          tester,
        ) async {
          _setWidth(tester, width);
          await tester.pumpWidget(
            _host(days: _days(9), selected: 5, design: true, textScale: scale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
