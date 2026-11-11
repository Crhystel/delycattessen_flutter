import 'package:delycattessen_flutter/features/children/utils/parent_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pushes a screen with a button; [next] builds what that button opens.
Widget _screen(String label, WidgetBuilder? next) => Builder(
  builder: (context) => Scaffold(
    body: TextButton(
      onPressed: next == null
          ? null
          : () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: next)),
      child: Text(label),
    ),
  ),
);

void main() {
  testWidgets('openWalletMovements closes the pushed screens and asks for the '
      'movements of that child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _screen(
          'primera',
          (_) => _screen(
            'segunda',
            (_) => Builder(
              builder: (deep) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      ParentNavigation.openWalletMovements(deep, childId: 7),
                  child: const Text('ver movimientos'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final before = ParentNavigation.walletMovements.value;
    await tester.tap(find.text('primera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('segunda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ver movimientos'));
    await tester.pumpAndSettle();

    // Both pushed routes are closed: only the first one is left.
    expect(find.text('primera'), findsOneWidget);
    expect(find.text('ver movimientos'), findsNothing);
    final request = ParentNavigation.walletMovements.value;
    expect(request, isNot(same(before)));
    expect(request!.childId, 7);
  });

  testWidgets('openWalletRecharge closes the pushed screens and asks to '
      'recharge that child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _screen(
          'primera',
          (_) => Builder(
            builder: (deep) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    ParentNavigation.openWalletRecharge(deep, childId: 9),
                child: const Text('recargar'),
              ),
            ),
          ),
        ),
      ),
    );

    final before = ParentNavigation.walletRecharge.value;
    final movementsBefore = ParentNavigation.walletMovements.value;
    await tester.tap(find.text('primera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('recargar'));
    await tester.pumpAndSettle();

    expect(find.text('primera'), findsOneWidget);
    expect(find.text('recargar'), findsNothing);
    final request = ParentNavigation.walletRecharge.value;
    expect(request, isNot(same(before)));
    expect(request!.childId, 9);
    // It does not pretend to be a movements request.
    expect(ParentNavigation.walletMovements.value, same(movementsBefore));
  });
}
