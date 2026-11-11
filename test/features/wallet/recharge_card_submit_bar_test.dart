import 'package:delycattessen_flutter/features/wallet/screens/recharge_card_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _navBarHeight = 48.0;

Future<void> _pump(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: _navBarHeight);
  tester.view.viewPadding = const FakeViewPadding(bottom: _navBarHeight);
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

void main() {
  testWidgets('the pay button stays above the system navigation bar', (
    tester,
  ) async {
    await _pump(tester, size: const Size(390, 700));

    final button = find.widgetWithText(ElevatedButton, 'Confirmar pago');
    expect(button, findsOneWidget);
    final rect = tester.getRect(button);

    expect(rect.bottom, lessThanOrEqualTo(700 - _navBarHeight));
  });

  testWidgets('the pay button fills the width of the form', (tester) async {
    await _pump(tester, size: const Size(390, 700));

    final rect = tester.getRect(
      find.widgetWithText(ElevatedButton, 'Confirmar pago'),
    );

    // 20 px of side padding on each side.
    expect(rect.left, 20);
    expect(rect.right, 390 - 20);
  });

  testWidgets('the pay button does not scroll away with the form', (
    tester,
  ) async {
    await _pump(tester, size: const Size(390, 700));
    final button = find.widgetWithText(ElevatedButton, 'Confirmar pago');
    final before = tester.getRect(button);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();

    expect(tester.getRect(button), before);
  });

  testWidgets('an incomplete form is reported as a notification', (
    tester,
  ) async {
    await _pump(tester, size: const Size(390, 700));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar pago'));
    await tester.pump();

    expect(find.text('Revisa tus datos'), findsOneWidget);

    // Let the notification auto-dismiss so no timer is left pending.
    await tester.pump(const Duration(seconds: 6));
  });
}
