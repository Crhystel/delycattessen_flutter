import 'package:delycattessen_flutter/features/wallet/widgets/wallet_summary_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
  double consumed = 6,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: WalletSummaryHeader(
            balance: 9,
            consumed: consumed,
            consumedLabel: 'Consumido en septiembre',
          ),
        ),
      ),
    ),
  );
  // The first test would otherwise measure with the fallback font, wider
  // than Nunito, because the bundled font loads asynchronously.
  await tester.runAsync(GoogleFonts.pendingFonts);
  await tester.pump();
}

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('"Consumido en septiembre" is never cut at 340 px, text '
        'x$scale', (tester) async {
      await _pump(tester, width: 340, textScale: scale);

      expect(tester.takeException(), isNull);
      final label = tester.renderObject<RenderParagraph>(
        find.text('Consumido en septiembre'),
      );
      expect(label.didExceedMaxLines, isFalse);
      expect(find.text('\$6.00'), findsOneWidget);
    });
  }

  testWidgets('both tiles are as tall as each other side by side', (
    tester,
  ) async {
    await _pump(tester, width: 340);

    final balance = tester.getSize(
      find
          .ancestor(
            of: find.text('Saldo actual'),
            matching: find.byType(Container),
          )
          .first,
    );
    final consumed = tester.getSize(
      find
          .ancestor(
            of: find.text('Consumido en septiembre'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(balance.height, consumed.height);
    expect(balance.width, consumed.width);
  });

  testWidgets('with very large text the tiles stack at full width', (
    tester,
  ) async {
    await _pump(tester, width: 340, textScale: 2);

    final balance = tester.getTopLeft(find.text('Saldo actual'));
    final consumed = tester.getTopLeft(find.text('Consumido en septiembre'));
    expect(consumed.dy, greaterThan(balance.dy));
    expect(consumed.dx, closeTo(balance.dx, 1.5)); // the border adds 1
  });

  testWidgets('a long amount scales down instead of overflowing', (
    tester,
  ) async {
    await _pump(tester, width: 320, consumed: 123456.78);

    expect(tester.takeException(), isNull);
  });
}
