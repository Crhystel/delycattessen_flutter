import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/models/parental_control_model.dart';
import 'package:delycattessen_flutter/features/children/providers/child_movements_controller.dart';
import 'package:delycattessen_flutter/features/children/providers/child_settings_controller.dart';
import 'package:delycattessen_flutter/features/children/screens/child_detail_screen.dart';
import 'package:delycattessen_flutter/features/children/services/parental_control_service.dart';
import 'package:delycattessen_flutter/features/users/models/allergy_models.dart';
import 'package:delycattessen_flutter/features/wallet/models/wallet_models.dart';
import 'package:delycattessen_flutter/features/wallet/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Child _child({int? walletId = 9}) => Child(
  id: 3,
  firstName: 'Pepito',
  lastName: 'Pérez',
  institutionName: 'Martin Cerere',
  balance: 50.01,
  walletId: walletId,
);

TransactionModel _tx(
  int id,
  String name,
  String type,
  double amount,
  DateTime at,
) => TransactionModel(
  id: id,
  displayName: name,
  amount: amount,
  gateway: '',
  status: 'success',
  type: type,
  time: '10 nov',
  createdAt: at,
  items: const [],
);

class _FakeAuth extends AuthService {
  @override
  Future<List<Allergen>> getStudentAllergies(int studentId) async => [
    Allergen(id: 1, name: 'Sulfitos'),
  ];
}

class _FakeParental extends ParentalControlService {
  @override
  Future<ParentalControl> getParentalControl(int studentId) async =>
      ParentalControl(
        dailyLimitEnabled: true,
        dailyLimitAmount: 1,
        allowedDaysEnabled: false,
        allowedDays: const [],
      );
}

class _FakeWallet extends WalletService {
  _FakeWallet(this.items, {this.fail = false});

  final List<TransactionModel> items;
  final bool fail;

  @override
  Future<List<TransactionModel>> getTransactions(int walletId) async {
    if (fail) throw Exception('sin conexión');
    return items;
  }
}

Future<void> _open(
  WidgetTester tester, {
  required Child child,
  _FakeWallet? wallet,
  Size size = const Size(390, 1600),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = ChildSettingsController(
    studentId: child.id,
    authService: _FakeAuth(),
    parentalService: _FakeParental(),
  );
  addTearDown(settings.dispose);
  ChildMovementsController? movements;
  if (wallet != null && child.walletId != null) {
    movements = ChildMovementsController(
      walletId: child.walletId!,
      walletService: wallet,
    );
    addTearDown(movements.dispose);
  }
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ChildDetailScreen(
        child: child,
        settings: settings,
        movements: movements,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the blue balance card, Su día and the three latest '
      'movements', (tester) async {
    final base = DateTime(2026, 11, 10, 12);
    await _open(
      tester,
      child: _child(),
      wallet: _FakeWallet([
        _tx(
          1,
          'Recarga',
          'recharge',
          20,
          base.subtract(const Duration(days: 4)),
        ),
        _tx(2, 'Pollo asado', 'consumption', 3.5, base),
        _tx(
          3,
          'Jugo',
          'consumption',
          1,
          base.subtract(const Duration(days: 1)),
        ),
        _tx(
          4,
          'Galleta',
          'consumption',
          0.8,
          base.subtract(const Duration(days: 2)),
        ),
      ]),
    );

    expect(find.text('Pepito Pérez'), findsOneWidget);
    expect(find.text('Saldo actual'), findsOneWidget);
    expect(find.text('\$50.01'), findsOneWidget);
    expect(find.text('Recargar'), findsOneWidget);

    expect(find.text('Su día'), findsOneWidget);
    expect(find.text('Límite diario'), findsOneWidget);
    expect(find.text('Límite \$1.00/día'), findsOneWidget);
    expect(find.text('Alergias'), findsOneWidget);
    expect(find.text('Sulfitos'), findsOneWidget);
    expect(
      find.text('Te avisamos en el menú si un plato las contiene'),
      findsOneWidget,
    );

    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Ver todo'), findsOneWidget);
    // Only the 3 newest: the 4-day-old recharge is left out.
    expect(find.text('Pollo asado'), findsOneWidget);
    expect(find.text('Jugo'), findsOneWidget);
    expect(find.text('Galleta'), findsOneWidget);
    expect(find.text('Recarga'), findsNothing);
    expect(find.text('−\$3.50'), findsOneWidget);
  });

  testWidgets('hides Movimientos when the child has no wallet', (tester) async {
    await _open(tester, child: _child(walletId: null));

    expect(find.text('Movimientos'), findsNothing);
    expect(find.text('Su día'), findsOneWidget);
  });

  testWidgets('shows an empty state without movements', (tester) async {
    await _open(tester, child: _child(), wallet: _FakeWallet(const []));

    expect(find.textContaining('Aún no hay movimientos'), findsOneWidget);
  });

  testWidgets('shows the error and a retry when movements fail', (
    tester,
  ) async {
    await _open(
      tester,
      child: _child(),
      wallet: _FakeWallet(const [], fail: true),
    );

    expect(find.text('sin conexión'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  for (final (label, size, scale) in [
    ('small phone', const Size(320, 568), 1.0),
    ('small phone, big text', const Size(320, 568), 2.0),
    ('tablet', const Size(768, 1024), 1.0),
  ]) {
    testWidgets('fits without overflow: $label', (tester) async {
      await _open(
        tester,
        child: _child(),
        wallet: _FakeWallet([
          _tx(
            1,
            'Pollo asado con arroz y ensalada',
            'consumption',
            3.5,
            DateTime(2026, 11, 10),
          ),
        ]),
        size: size,
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
    });
  }

  test('ChildMovementsController.latest sorts newest first', () {
    final base = DateTime(2026, 11, 10);
    final result = ChildMovementsController.latest([
      _tx(1, 'a', 'recharge', 1, base),
      _tx(2, 'b', 'recharge', 1, base.add(const Duration(days: 2))),
      _tx(3, 'c', 'recharge', 1, base.add(const Duration(days: 1))),
    ], 2);

    expect(result.map((t) => t.id), [2, 3]);
  });
}
