import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/children/widgets/child_switch_bar.dart';
import 'package:delycattessen_flutter/features/wallet/screens/wallet_recharge_screen.dart';
import 'package:delycattessen_flutter/features/wallet/widgets/recharge_submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Child _child(
  int id,
  String first,
  String last, {
  int? walletId,
  double? balance,
}) => Child(
  id: id,
  firstName: first,
  lastName: last,
  institutionName: 'Martin Cerere',
  balance: balance,
  walletId: walletId,
);

class _FakeAuth extends AuthService {
  _FakeAuth(this.children);

  final List<Child> children;

  @override
  Future<List<Child>> getChildren() async => children;
}

final _julieta = _child(3, 'Julieta', 'Venegas', walletId: 1, balance: 9);
final _pedro = _child(4, 'Pedro', 'Gómez', walletId: 2, balance: 4.5);
final _sinBilletera = _child(5, 'Lucia', 'Mora');

Widget _screen({
  WalletSection section = WalletSection.recharge,
  List<Child>? children,
}) => ChangeNotifierProvider(
  create: (_) =>
      ChildrenProvider(authService: _FakeAuth(children ?? [_julieta])),
  child: MaterialApp(home: WalletRechargeScreen(initialSection: section)),
);

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(screen);
  await tester.pumpAndSettle();
}

Future<void> _switchTo(WidgetTester tester, String name) async {
  await tester.tap(find.byType(ChildSwitchBar));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('shows the "after recharge" pill only with an amount', (
    tester,
  ) async {
    await _pump(tester, _screen());

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

  testWidgets('typing an amount updates the pill and the button', (
    tester,
  ) async {
    await _pump(tester, _screen());

    await tester.enterText(find.byType(TextField), '7.50');
    await tester.pump();

    expect(find.textContaining('Después de recargar'), findsOneWidget);
    expect(find.textContaining('\$16.50'), findsOneWidget);
    expect(find.text('Recargar \$7.50 a Julieta'), findsOneWidget);
  });

  testWidgets('can open straight on Movimientos (redirect from another '
      'screen)', (tester) async {
    await _pump(tester, _screen(section: WalletSection.movements));

    // The recharge form is hidden; the movements section is what shows (here
    // without a backend, so it shows its retry state).
    expect(find.text('Monto a recargar').hitTestable(), findsNothing);
    expect(find.text('Reintentar').hitTestable(), findsOneWidget);
  });

  testWidgets('opens on Recargar by default', (tester) async {
    await _pump(tester, _screen());

    expect(find.text('Monto a recargar').hitTestable(), findsOneWidget);
  });

  testWidgets('the profile bubble sits at the same height as in the other '
      'tabs: at the safe-area top plus the shared inset', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ChildrenProvider(authService: _FakeAuth([_julieta])),
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewPadding: const EdgeInsets.only(top: 40)),
            child: child!,
          ),
          home: WalletRechargeScreen(
            profileAction: Container(
              key: const Key('bubble'),
              width: 40,
              height: 40,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // inset (40) + the shared 16: the same place as in the other tabs.
    expect(tester.getTopLeft(find.byKey(const Key('bubble'))).dy, 56);
    expect(tester.takeException(), isNull);
  });

  group('changing the child', () {
    testWidgets('picking another child shows their balance and button', (
      tester,
    ) async {
      await _pump(tester, _screen(children: [_julieta, _pedro]));
      await tester.tap(find.text('\$5'));
      await tester.pumpAndSettle();
      expect(find.text('Recargar \$5.00 a Julieta'), findsOneWidget);

      await _switchTo(tester, 'Pedro Gómez');

      expect(find.text('Saldo actual de Pedro'), findsOneWidget);
      expect(find.text('\$4.50'), findsOneWidget);
      expect(find.text('Recargar \$5.00 a Pedro'), findsOneWidget);
      expect(find.text('Saldo actual de Julieta'), findsNothing);
    });

    testWidgets('a child without wallet shows the notice, no active button '
        'and empty movements', (tester) async {
      await _pump(tester, _screen(children: [_julieta, _sinBilletera]));

      await _switchTo(tester, 'Lucia Mora');

      // The bar follows the choice and stays usable.
      expect(find.byType(ChildSwitchBar), findsOneWidget);
      expect(find.text('Lucia Mora'), findsOneWidget);
      expect(
        find.text('Este hijo aún no tiene billetera activa'),
        findsWidgets,
      );
      expect(find.byType(RechargeSubmitButton), findsNothing);
      expect(find.text('Monto a recargar'), findsNothing);
      expect(find.text('Saldo actual de Julieta'), findsNothing);

      await tester.tap(find.text('Movimientos'));
      await tester.pumpAndSettle();
      expect(
        find.text('Este hijo aún no tiene billetera activa').hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);

      // Going back to a child with wallet brings the form back.
      await _switchTo(tester, 'Julieta Venegas');
      await tester.tap(find.text('Recargar').first);
      await tester.pumpAndSettle();
      expect(find.text('Saldo actual de Julieta'), findsOneWidget);
    });
  });
}
