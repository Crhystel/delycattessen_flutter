import 'package:delycattessen_flutter/features/wallet/screens/wallet_recharge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _screen() => MaterialApp(
  home: WalletRechargeScreen(
    embedded: true,
    children: [
      ChildOption(
        walletId: 1,
        name: 'Julieta Venegas',
        currentBalance: 9,
        studentId: 3,
      ),
    ],
  ),
);

void main() {
  testWidgets('embedded: shows the "after recharge" pill only with an amount', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('Billetera'), findsOneWidget);
    expect(find.text('Saldo actual de Julieta'), findsOneWidget);
    expect(find.text('\$9.00'), findsOneWidget);
    expect(find.textContaining('Después de recargar'), findsNothing);
    expect(find.text('Recargar saldo seguro'), findsOneWidget);

    await tester.tap(find.text('\$10'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Después de recargar'), findsOneWidget);
    expect(find.text('Recargar \$10.00 a Julieta'), findsOneWidget);
  });

  testWidgets('embedded: typing an amount updates the pill and the button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '7.50');
    await tester.pump();

    expect(find.textContaining('Después de recargar'), findsOneWidget);
    expect(find.textContaining('\$16.50'), findsOneWidget);
    expect(find.text('Recargar \$7.50 a Julieta'), findsOneWidget);
  });
}
