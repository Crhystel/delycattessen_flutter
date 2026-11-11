import 'package:delycattessen_flutter/core/theme/app_colors.dart';
import 'package:delycattessen_flutter/core/widgets/floating_bubbles.dart';
import 'package:delycattessen_flutter/core/widgets/form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the title and children on the ink50 background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FormPage(title: 'Mi perfil', children: [Text('contenido')]),
      ),
    );

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('contenido'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.ink50,
    );
  });

  testWidgets('scrolls when the content is taller than the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: FormPage(
          title: 'Largo',
          children: [for (var i = 0; i < 30; i++) Text('fila $i')],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();
    expect(find.text('fila 29'), findsOneWidget);
  });

  testWidgets('header instead of app bar, bubbles and 20 margins', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: FormPage(title: 'Mi perfil', children: [Text('contenido')]),
      ),
    );

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.byType(FloatingBubbles), findsOneWidget);
    expect(tester.getTopLeft(find.text('contenido')).dx, 20);
    expect(tester.takeException(), isNull);
  });
}
