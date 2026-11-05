import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/auth/screens/profile_password_screen.dart';
import 'package:delycattessen_flutter/features/auth/widgets/password_requirements.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/profile_test_support.dart';

const _strong = 'New-Passw0rd!';

Future<FakeAuthService> _open(
  WidgetTester tester, {
  FakeAuthService? service,
}) async {
  final fake = service ?? FakeAuthService();
  await openScreen(tester, ProfilePasswordScreen(authService: fake));
  return fake;
}

Future<void> _fill(
  WidgetTester tester, {
  String current = 'Old-Passw0rd!',
  String password = _strong,
  String? confirmation,
}) async {
  await typeInto(tester, 'Contraseña actual', current);
  await typeInto(tester, 'Nueva contraseña', password);
  await typeInto(
    tester,
    'Confirmar nueva contraseña',
    confirmation ?? password,
  );
}

void main() {
  testWidgets('shows the three fields and the live requirements guide', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Contraseña actual'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
    expect(find.byType(PasswordRequirements), findsOneWidget);
  });

  testWidgets('warns when the confirmation differs', (tester) async {
    await _open(tester);
    await _fill(tester, confirmation: '${_strong}x');

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('does not call the network with weak, mismatched or empty data', (
    tester,
  ) async {
    final service = await _open(tester);

    await _fill(tester, password: 'abc');
    await tapButton(tester, 'Guardar contraseña');
    await _fill(tester, confirmation: '${_strong}x');
    await tapButton(tester, 'Guardar contraseña');
    await typeInto(tester, 'Contraseña actual', '');
    await _fill(tester, current: '');
    await tapButton(tester, 'Guardar contraseña');

    expect(service.calls, isEmpty);
    expect(find.byType(ProfilePasswordScreen), findsOneWidget);
  });

  testWidgets('changes the password and closes', (tester) async {
    final service = await _open(tester);

    await _fill(tester);
    await tapButton(tester, 'Guardar contraseña');
    await tester.pumpAndSettle();

    expect(service.calls, ['password']);
    expect(service.lastPassword!.currentPassword, 'Old-Passw0rd!');
    expect(service.lastPassword!.newPassword, _strong);
    expect(service.lastPassword!.confirmPassword, _strong);
    expect(hostOf(tester).popped, isTrue);
  });

  testWidgets('stays open with the message when the backend rejects it', (
    tester,
  ) async {
    final service = FakeAuthService()
      ..passwordError = const ApiException(
        'La contraseña actual es incorrecta.',
        statusCode: 400,
      );
    await _open(tester, service: service);

    await _fill(tester);
    await tapButton(tester, 'Guardar contraseña');

    expect(service.calls, ['password']);
    expect(find.byType(ProfilePasswordScreen), findsOneWidget);
    expect(find.text('La contraseña actual es incorrecta.'), findsOneWidget);
  });
}
