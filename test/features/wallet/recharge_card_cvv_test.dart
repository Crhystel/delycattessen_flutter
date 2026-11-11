import 'package:delycattessen_flutter/features/wallet/screens/recharge_card_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(
      home: RechargeCardFormScreen(
        walletId: 1,
        childName: 'Julieta Venegas',
        amount: 10,
      ),
    ),
  );
  await tester.pump();
}

/// The CVV field: the one with the "•••" hint.
Finder get _cvvField => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == '•••',
);

void main() {
  testWidgets('the CVV takes at most 4 digits (American Express)', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(_cvvField, '12345');
    await tester.pump();

    expect(tester.widget<TextField>(_cvvField).controller!.text, '1234');
  });

  testWidgets('the CVV ignores letters and symbols', (tester) async {
    await _pump(tester);

    await tester.enterText(_cvvField, '1a2-b');
    await tester.pump();

    expect(tester.widget<TextField>(_cvvField).controller!.text, '12');
  });
}
