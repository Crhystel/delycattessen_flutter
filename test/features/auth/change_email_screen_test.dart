import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/auth/screens/change_email_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/profile_test_support.dart';

Future<FakeAuthService> _open(
  WidgetTester tester, {
  FakeAuthService? service,
}) async {
  final fake = service ?? FakeAuthService();
  await openScreen(tester, ChangeEmailScreen(me: testMe(), authService: fake));
  return fake;
}

void main() {
  testWidgets('shows the current email and asks for the password', (
    tester,
  ) async {
    await _open(tester);

    expect(find.textContaining('docente@mail.com'), findsOneWidget);
    expect(find.text('Nuevo correo'), findsWidgets);
    expect(find.text('Contraseña actual'), findsOneWidget);
  });

  testWidgets('does not call the network without the current password', (
    tester,
  ) async {
    final service = await _open(tester);

    await typeInto(tester, 'Nuevo correo', 'nuevo@mail.com');
    await tapButton(tester, 'Guardar correo');

    expect(service.calls, isEmpty);
    expect(find.byType(ChangeEmailScreen), findsOneWidget);
  });

  testWidgets('does not call the network with an invalid or same email', (
    tester,
  ) async {
    final service = await _open(tester);
    await typeInto(tester, 'Contraseña actual', 'Old-Passw0rd!');

    await typeInto(tester, 'Nuevo correo', 'no-es-un-correo');
    await tapButton(tester, 'Guardar correo');
    await typeInto(tester, 'Nuevo correo', 'DOCENTE@mail.com');
    await tapButton(tester, 'Guardar correo');

    expect(service.calls, isEmpty);
  });

  testWidgets('sends the new email with the current password and closes', (
    tester,
  ) async {
    final service = await _open(tester);

    await typeInto(tester, 'Nuevo correo', 'Nuevo@Mail.com');
    await typeInto(tester, 'Contraseña actual', 'Old-Passw0rd!');
    await tapButton(tester, 'Guardar correo');
    await tester.pumpAndSettle();

    expect(service.calls, ['profile']);
    final json = service.lastProfile!.toJson();
    expect(json['email'], 'nuevo@mail.com');
    expect(json['current_password'], 'Old-Passw0rd!');
    expect(json['first_name'], 'Ana'); // names travel unchanged
    expect((hostOf(tester).result as dynamic).email, 'nuevo@mail.com');
  });

  testWidgets('stays open with the message when the password is wrong', (
    tester,
  ) async {
    final service = FakeAuthService()
      ..profileError = const ApiException(
        'La contraseña actual es incorrecta.',
        statusCode: 400,
      );
    await _open(tester, service: service);

    await typeInto(tester, 'Nuevo correo', 'nuevo@mail.com');
    await typeInto(tester, 'Contraseña actual', 'mala');
    await tapButton(tester, 'Guardar correo');

    expect(service.calls, ['profile']);
    expect(find.byType(ChangeEmailScreen), findsOneWidget);
    expect(find.text('La contraseña actual es incorrecta.'), findsOneWidget);
  });
}
