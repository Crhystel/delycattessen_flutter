import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/features/wallet/widgets/recharge_amount_input.dart';
import 'package:delycattessen_flutter/features/wallet/widgets/recharge_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<TextEditingController> _pumpField(
  WidgetTester tester, {
  String text = '',
  Size size = const Size(390, 600),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = TextEditingController(text: text);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      // The real theme: it pads every input by 14, which pushed the number up.
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: RechargeAmountField(controller: controller),
        ),
      ),
    ),
  );
  return controller;
}

/// Horizontal centre of the amount field minus the centre of the box: the
/// NUMBER (not the "$" + number block) must sit in the middle.
double _offCenter(WidgetTester tester) {
  final box = tester.getRect(find.byType(Container).first);
  final text = tester.getRect(find.byType(EditableText));
  return text.center.dx - box.center.dx;
}

/// Vertical centre of the amount minus the centre of the box.
double _offMiddle(WidgetTester tester) {
  final box = tester.getRect(find.byType(Container).first);
  final text = tester.getRect(find.byType(EditableText));
  return text.center.dy - box.center.dy;
}

void main() {
  group('RechargeAmountField (design)', () {
    for (final text in ['', '5', '10.00', '1234.50']) {
      testWidgets('centres the number in the box: "$text"', (tester) async {
        await _pumpField(tester, text: text);

        expect(_offCenter(tester).abs(), lessThan(1));
        expect(_offMiddle(tester).abs(), lessThan(1));
        // The "$" stays to the left of the number, never over it.
        final dollar = tester.getRect(find.text('\$'));
        final field = tester.getRect(find.byType(EditableText));
        expect(dollar.right, lessThanOrEqualTo(field.left + 1));
        // ...and close to it: no 14 dp of theme padding between them.
        expect(field.left - dollar.right, lessThan(12));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the field hugs a short amount instead of a fixed width', (
      tester,
    ) async {
      await _pumpField(tester, text: '5');

      // Before it was a fixed 130 dp box with the number floating inside it.
      expect(tester.getSize(find.byType(TextField)).width, lessThan(100));
    });

    testWidgets('is smaller than before and fits a 340 phone with text x2', (
      tester,
    ) async {
      await _pumpField(
        tester,
        text: '1234.50',
        size: const Size(340, 700),
        textScale: 2,
      );

      final style = tester.widget<TextField>(find.byType(TextField)).style!;
      expect(style.fontSize, lessThanOrEqualTo(26));
      expect(tester.getSize(find.byType(Container).first).height, 60);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the balance card amount is 30 and the label 13', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RechargeBalanceCard(
            balance: 12.5,
            firstName: 'Julieta',
            amountController: controller,
          ),
        ),
      ),
    );

    final amount = tester.widget<Text>(find.text('\$12.50'));
    final label = tester.widget<Text>(find.text('Saldo actual de Julieta'));
    expect(amount.style!.fontSize, 30);
    expect(label.style!.fontSize, 13);
  });
}
