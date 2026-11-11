import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/core/widgets/greeting_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  );
}

void main() {
  final now = DateTime(2026, 11, 10);

  testWidgets('shows the date first and the greeting below it', (tester) async {
    await _pump(tester, GreetingText(name: 'Pepito Pérez', now: now));

    final date = find.text('Martes, 10 de noviembre');
    final hello = find.text('¡Hola, Pepito Pérez!');
    expect(date, findsOneWidget);
    expect(hello, findsOneWidget);
    expect(tester.getTopLeft(date).dy, lessThan(tester.getTopLeft(hello).dy));
  });

  testWidgets('falls back to "Usuario" when there is no name', (tester) async {
    await _pump(tester, GreetingText(name: '  ', now: now));

    expect(find.text('¡Hola, Usuario!'), findsOneWidget);
  });

  testWidgets('scale enlarges both lines (tablet POS)', (tester) async {
    await _pump(tester, GreetingText(name: 'Ana', now: now));
    final normal = tester.getSize(find.text('¡Hola, Ana!')).height;

    await _pump(tester, GreetingText(name: 'Ana', scale: 1.7, now: now));
    final big = tester.getSize(find.text('¡Hola, Ana!')).height;

    expect(big, greaterThan(normal));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('a very long name does not overflow at 320 px, text x$scale', (
      tester,
    ) async {
      await _pump(
        tester,
        GreetingText(
          name: 'María Fernanda de los Ángeles Rodríguez Martínez de la Torre',
          now: now,
        ),
        size: const Size(320, 640),
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
