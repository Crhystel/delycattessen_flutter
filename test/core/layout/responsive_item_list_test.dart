import 'package:delycattessen_flutter/core/layout/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _list({int count = 40}) => MaterialApp(
  home: Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverResponsiveItemList(
          itemCount: count,
          itemBuilder: (_, i) => SizedBox(height: 60, child: Text('item $i')),
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('one column on a phone, in order', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_list(count: 3));

    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('item 0')).dx,
      tester.getTopLeft(find.text('item 1')).dx,
    );
    expect(
      tester.getTopLeft(find.text('item 0')).dy,
      lessThan(tester.getTopLeft(find.text('item 1')).dy),
    );
  });

  testWidgets('scrolls until the last item', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_list(count: 40));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(find.text('item 39'), findsOneWidget);
  });

  testWidgets('uses several columns on a tablet', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_list(count: 6));

    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('item 0')).dy,
      tester.getTopLeft(find.text('item 1')).dy,
    ); // same row
    expect(
      tester.getTopLeft(find.text('item 0')).dx,
      lessThan(tester.getTopLeft(find.text('item 1')).dx),
    );
  });

  testWidgets('a last row with fewer items than columns still lays out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_list(count: 4)); // 3 columns: 3 + 1

    expect(find.text('item 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
