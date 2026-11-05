import 'package:delycattessen_flutter/core/layout/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _list({Widget? header, int count = 40}) => MaterialApp(
  home: Scaffold(
    body: ResponsiveItemList(
      header: header,
      itemCount: count,
      itemBuilder: (_, i) => SizedBox(height: 60, child: Text('item $i')),
    ),
  ),
);

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('without a header it behaves as before', (tester) async {
    phone(tester);
    await tester.pumpWidget(_list(count: 3));

    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
  });

  testWidgets('the header comes first and scrolls away with the items', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      _list(header: const SizedBox(height: 200, child: Text('cabecera'))),
    );

    expect(find.text('cabecera'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('cabecera')).dy,
      lessThan(tester.getTopLeft(find.text('item 0')).dy),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('cabecera'), findsNothing);
  });

  testWidgets(
    'the header takes no space once scrolled: every item is reachable',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        _list(
          header: const SizedBox(height: 300, child: Text('cabecera')),
          count: 5,
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();

      expect(find.text('item 4'), findsOneWidget);
    },
  );

  testWidgets('the header also works with several columns on a tablet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _list(
        header: const SizedBox(height: 100, child: Text('cabecera')),
        count: 6,
      ),
    );

    expect(find.text('cabecera'), findsOneWidget);
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('item 0')).dy,
      tester.getTopLeft(find.text('item 1')).dy,
    ); // same row: it is a multi-column layout
  });
}
