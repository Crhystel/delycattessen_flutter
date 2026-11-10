import 'package:delycattessen_flutter/features/wallet/widgets/kushki_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows who processes the payment with the Kushki logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: KushkiBadge())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pago procesado por'), findsOneWidget);
    final logo = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(logo.semanticsLabel, 'Kushki');
    expect(tester.takeException(), isNull);
  });
}
