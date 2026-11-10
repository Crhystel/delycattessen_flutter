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
}) => MaterialApp(
  home: Scaffold(
    body: MenuDaysStrip(
      days: days,
      selectedDayId: selected,
      onSelect: onSelect ?? (_) {},
    ),
  ),
);

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
}
