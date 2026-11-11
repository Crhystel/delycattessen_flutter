import 'package:delycattessen_flutter/core/theme/app_colors.dart';
import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/features/children/widgets/alerts_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int count,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AlertsSectionHeader(count: count),
        ),
      ),
    ),
  );
}

Finder get _badge => find.byKey(const ValueKey('alerts-count-badge'));

void main() {
  testWidgets('shows the title and the number of alerts', (tester) async {
    await _pump(tester, count: 3);

    expect(find.text('Avisos'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('does not overflow with a big count, large text and 320 px', (
    tester,
  ) async {
    await _pump(tester, count: 12, width: 320, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('a single digit makes the badge a 22 px circle', (tester) async {
    await _pump(tester, count: 1);

    final size = tester.getSize(_badge);
    expect(size.width, 22);
    expect(size.height, 22);
    final decoration =
        tester.widget<Container>(_badge).decoration as BoxDecoration;
    expect(decoration.color, AppColors.danger500);
  });

  testWidgets('more digits make the badge a pill', (tester) async {
    await _pump(tester, count: 12);

    final size = tester.getSize(_badge);
    expect(size.width, greaterThan(size.height));
  });

  testWidgets('is announced as a header with the count', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, count: 2);

    expect(find.bySemanticsLabel('Avisos, 2'), findsOneWidget);
    handle.dispose();
  });
}
