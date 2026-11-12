import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/core/network/base_api_service.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/screens/student_registration_screen.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/children/screens/deactivate_child_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../auth/support/profile_test_support.dart';

Child _child(int id, String name) => Child(
  id: id,
  firstName: name,
  lastName: 'Pérez',
  username: name.toLowerCase(),
  institutionName: 'Martim Cereré',
);

final _luis = _child(3, 'Luis');
final _ana = _child(4, 'Ana');

class _FakeService extends AuthService {
  _FakeService({
    this.check = const ChildRemovalCheck(canRemove: true),
    List<Child>? children,
  }) : children = children ?? [_luis, _ana];

  ChildRemovalCheck check;
  List<Child> children;
  Object? checkError;
  Object? removeError;
  int checkCalls = 0;
  final List<(int, String)> removals = [];

  @override
  Future<ChildRemovalCheck> getChildRemovalCheck(int studentId) async {
    checkCalls++;
    if (checkError != null) throw checkError!;
    return check;
  }

  @override
  Future<void> removeChild(int studentId, String parentPassword) async {
    removals.add((studentId, parentPassword));
    if (removeError != null) throw removeError!;
    children = children.where((c) => c.id != studentId).toList();
  }

  @override
  Future<List<Child>> getChildren() async => children;
}

Future<ChildrenProvider> _open(
  WidgetTester tester,
  _FakeService service,
) async {
  final provider = ChildrenProvider(authService: service);
  await provider.ensureLoaded();
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<ChildrenProvider>.value(
      value: provider,
      child: MaterialApp(
        home: ResultHost(
          screen: DeactivateChildScreen(child: _luis, authService: service),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return provider;
}

final _removeButton = find.widgetWithText(OutlinedButton, 'Dar de baja a Luis');

void main() {
  testWidgets('lists the conditions and offers the removal when all are met', (
    tester,
  ) async {
    await _open(tester, _FakeService());

    expect(find.text('Sin saldo en la billetera'), findsOneWidget);
    expect(find.text('Sin preórdenes pendientes'), findsOneWidget);
    expect(find.text('Sin recargas en proceso'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
    expect(find.text('Tu contraseña'), findsOneWidget);
    expect(_removeButton, findsOneWidget);
  });

  testWidgets('a balance blocks the removal and says how much is left', (
    tester,
  ) async {
    await _open(
      tester,
      _FakeService(
        check: const ChildRemovalCheck(canRemove: false, balance: 2.5),
      ),
    );

    expect(find.text('Todavía tiene \$2.50'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.text('Tu contraseña'), findsNothing);
    expect(_removeButton, findsNothing);
  });

  testWidgets('shows every reason that blocks the removal', (tester) async {
    await _open(
      tester,
      _FakeService(
        check: const ChildRemovalCheck(
          canRemove: false,
          balance: 1,
          pendingPreOrders: 2,
          pendingRecharges: 1,
        ),
      ),
    );

    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(3));
    expect(find.text('2 preórdenes por resolver'), findsOneWidget);
    expect(find.text('1 recarga por resolver'), findsOneWidget);
  });

  testWidgets('a failed check can be retried', (tester) async {
    final service = _FakeService()..checkError = ApiException('Sin conexión');
    await _open(tester, service);

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(_removeButton, findsNothing);

    service.checkError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(service.checkCalls, 2);
    expect(_removeButton, findsOneWidget);
  });

  testWidgets('without the parent password nothing is sent', (tester) async {
    final service = _FakeService();
    await _open(tester, service);

    await tester.tap(_removeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Falta tu contraseña'), findsOneWidget);
    expect(find.text('Dar de baja a Luis'), findsWidgets);
    expect(service.removals, isEmpty);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('cancelling the final confirmation removes nothing', (
    tester,
  ) async {
    final service = _FakeService();
    await _open(tester, service);
    await typeInto(tester, 'Tu contraseña', 'Parent-Passw0rd!');

    await tester.tap(_removeButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(service.removals, isEmpty);
    expect(find.byType(DeactivateChildScreen), findsOneWidget);
  });

  testWidgets(
    'a confirmed removal goes back to the start and drops the child',
    (tester) async {
      final service = _FakeService();
      final provider = await _open(tester, service);
      await typeInto(tester, 'Tu contraseña', 'Parent-Passw0rd!');

      await tester.tap(_removeButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Dar de baja'));
      await tester.pumpAndSettle();

      expect(service.removals, [(3, 'Parent-Passw0rd!')]);
      expect(find.byType(DeactivateChildScreen), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
      expect(provider.children.map((c) => c.id), [4]);
      expect(find.text('Hijo dado de baja'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    },
  );

  testWidgets('removing the last child leads to the child registration', (
    tester,
  ) async {
    // The registration screen loads the sedes as soon as it opens.
    final original = BaseApiService.httpClient;
    BaseApiService.httpClient = MockClient(
      (_) async => http.Response('[]', 200),
    );
    addTearDown(() => BaseApiService.httpClient = original);
    FlutterSecureStorage.setMockInitialValues({});

    final service = _FakeService(children: [_luis]);
    final provider = await _open(tester, service);
    await typeInto(tester, 'Tu contraseña', 'Parent-Passw0rd!');

    await tester.tap(_removeButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Dar de baja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(StudentRegistrationScreen), findsOneWidget);
    // The sede dropdown of that screen overflows at this test size; the layout
    // of the registration screen is not what is under test here.
    tester.takeException();
    expect(provider.children, isEmpty);
    expect(provider.hasLoadedOnce, isFalse);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a wrong password shows the error and keeps the screen', (
    tester,
  ) async {
    final service = _FakeService()
      ..removeError = ApiException('Tu contraseña es incorrecta.');
    final provider = await _open(tester, service);
    await typeInto(tester, 'Tu contraseña', 'mala');

    await tester.tap(_removeButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Dar de baja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tu contraseña es incorrecta.'), findsOneWidget);
    expect(find.byType(DeactivateChildScreen), findsOneWidget);
    expect(provider.children, hasLength(2));
    // The conditions are checked again: they may have changed.
    expect(service.checkCalls, 2);
    await tester.pump(const Duration(seconds: 6));
  });
}
