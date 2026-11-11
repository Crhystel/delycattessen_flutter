import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/auth/widgets/password_requirements.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/support/profile_test_support.dart';

const _strong = 'New-Passw0rd!';

final _child = Child(
  id: 3,
  firstName: 'Luis',
  lastName: 'Pérez',
  username: 'luisp',
  institutionName: 'Martim Cereré',
);

class _FakeChildService extends AuthService {
  final List<int> calls = [];
  ChildPasswordChange? sent;
  ApiException? error;

  @override
  Future<void> changeChildPassword(
    int studentId,
    ChildPasswordChange data,
  ) async {
    calls.add(studentId);
    sent = data;
    if (error != null) throw error!;
  }
}

Future<_FakeChildService> _open(
  WidgetTester tester, {
  _FakeChildService? service,
}) async {
  final fake = service ?? _FakeChildService();
  await openScreen(
    tester,
    EditChildPasswordScreen(child: _child, authService: fake),
  );
  return fake;
}

Future<void> _fill(
  WidgetTester tester, {
  String parent = 'Parent-Passw0rd!',
  String password = _strong,
  String? confirmation,
}) async {
  await typeInto(tester, 'Tu contraseña', parent);
  await typeInto(tester, 'Nueva contraseña', password);
  await typeInto(
    tester,
    'Confirmar nueva contraseña',
    confirmation ?? password,
  );
}

void main() {
  testWidgets('asks for the parent password, the new one and its guide', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Tu contraseña'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
    expect(find.byType(PasswordRequirements), findsOneWidget);
  });

  testWidgets('does not call the network with weak, mismatched or empty data', (
    tester,
  ) async {
    final service = await _open(tester);

    await _fill(tester, password: 'abc');
    await tapButton(tester, 'Guardar contraseña');
    await _fill(tester, confirmation: '${_strong}x');
    await tapButton(tester, 'Guardar contraseña');
    await _fill(tester, parent: '');
    await tapButton(tester, 'Guardar contraseña');

    expect(service.calls, isEmpty);
    expect(find.byType(EditChildPasswordScreen), findsOneWidget);
  });

  testWidgets('sends the parent password with the new one and closes', (
    tester,
  ) async {
    final service = await _open(tester);

    await _fill(tester);
    await tapButton(tester, 'Guardar contraseña');
    await tester.pumpAndSettle();

    expect(service.calls, [3]);
    expect(service.sent!.parentPassword, 'Parent-Passw0rd!');
    expect(service.sent!.newPassword, _strong);
    expect(service.sent!.confirmPassword, _strong);
    expect(hostOf(tester).popped, isTrue);
  });

  testWidgets(
    'a wrong parent password keeps the screen open with the message',
    (tester) async {
      final service = _FakeChildService()
        ..error = const ApiException(
          'Tu contraseña es incorrecta.',
          statusCode: 400,
        );
      await _open(tester, service: service);

      await _fill(tester);
      await tapButton(tester, 'Guardar contraseña');

      expect(service.calls, [3]);
      expect(find.byType(EditChildPasswordScreen), findsOneWidget);
      expect(find.text('Tu contraseña es incorrecta.'), findsOneWidget);
    },
  );
}
