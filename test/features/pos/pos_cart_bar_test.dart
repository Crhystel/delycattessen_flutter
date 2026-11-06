import 'package:delycattessen_flutter/features/pos/widgets/pos_cart_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({VoidCallback? onClear, VoidCallback? onContinue}) => MaterialApp(
  home: Scaffold(
    bottomNavigationBar: PosCartBar(
      total: 7.5,
      itemCount: 3,
      onClear: onClear ?? () {},
      onContinue: onContinue ?? () {},
    ),
  ),
);

void main() {
  testWidgets('shows the total and the number of items', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('\$7.50'), findsOneWidget);
    expect(find.text('Continuar (3)'), findsOneWidget);
  });

  testWidgets('continue and empty-cart buttons call their callbacks', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _host(
        onClear: () => calls.add('clear'),
        onContinue: () => calls.add('continue'),
      ),
    );

    await tester.tap(find.byTooltip('Vaciar carrito'));
    await tester.tap(find.text('Continuar (3)'));

    expect(calls, ['clear', 'continue']);
  });
}
