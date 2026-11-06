import 'package:delycattessen_flutter/features/menu/widgets/catalog_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({int rows = 3}) => MaterialApp(
  home: Scaffold(
    body: CustomScrollView(
      slivers: [
        CatalogSectionSliver(
          title: 'Bebidas',
          slivers: [
            SliverList.builder(
              itemCount: rows,
              itemBuilder: (_, i) =>
                  SizedBox(height: 80, child: Text('fila $i')),
            ),
          ],
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('shows the category title above its rows', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('Bebidas'), findsOneWidget);
    expect(find.text('fila 0'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Bebidas')).dy,
      lessThan(tester.getTopLeft(find.text('fila 0')).dy),
    );
  });

  testWidgets('the title scrolls away together with the rows', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(rows: 30));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Bebidas'), findsNothing);
    expect(find.text('fila 0'), findsNothing);
    expect(find.textContaining('fila '), findsWidgets);
  });

  testWidgets('draws a bordered rounded box around its content', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.byType(DecoratedSliver), findsOneWidget);
    final decoration =
        tester.widget<DecoratedSliver>(find.byType(DecoratedSliver)).decoration
            as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.borderRadius, isNotNull);
  });
}
