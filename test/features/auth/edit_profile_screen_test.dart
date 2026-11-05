import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/screens/edit_profile_screen.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/auth/widgets/password_requirements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _strong = 'New-Passw0rd!';

MeResponse _me({String firstName = 'Ana'}) => MeResponse(
  id: 7,
  email: 'docente@mail.com',
  firstName: firstName,
  lastName: 'Pérez',
  role: 'TEACHER',
  hasChildren: false,
  hasPaymentPin: false,
  mustChangePassword: false,
);

/// Records the calls in order and can fail the password step.
class _FakeAuthService extends AuthService {
  final List<String> calls = [];
  ChangePasswordRequest? passwordRequest;
  ApiException? passwordError;

  @override
  Future<MeResponse> updateProfile(ProfileUpdate data) async {
    calls.add('profile');
    return _me(firstName: data.names.firstName.trim());
  }

  @override
  Future<void> changePassword(ChangePasswordRequest data) async {
    calls.add('password');
    passwordRequest = data;
    if (passwordError != null) throw passwordError!;
  }
}

/// Opens the profile from a button so the pop result can be observed.
class _Host extends StatefulWidget {
  const _Host({required this.service, required this.canChangePassword});

  final AuthService service;
  final bool canChangePassword;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  MeResponse? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final updated = await Navigator.of(context).push<MeResponse>(
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  me: _me(),
                  canChangePassword: widget.canChangePassword,
                  authService: widget.service,
                ),
              ),
            );
            setState(() => result = updated);
          },
          child: const Text('abrir'),
        ),
      ),
    );
  }
}

Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Column));

Future<void> _open(
  WidgetTester tester,
  _FakeAuthService service, {
  bool canChangePassword = true,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: _Host(service: service, canChangePassword: canChangePassword),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: _field(label).first,
    matching: find.byType(TextField),
  );
  await tester.enterText(field.first, text);
  await tester.pump();
}

Future<void> _fillPassword(
  WidgetTester tester, {
  String current = 'Old-Passw0rd!',
  String password = _strong,
  String? confirmation,
}) async {
  await _type(tester, 'Contraseña actual', current);
  await _type(tester, 'Nueva contraseña', password);
  await _type(tester, 'Confirmar nueva contraseña', confirmation ?? password);
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Guardar cambios'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('shows the password section inside the same form', (
    tester,
  ) async {
    await _open(tester, _FakeAuthService());

    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Contraseña actual'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
    expect(find.byType(PasswordRequirements), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('hides the password section when it is not allowed', (
    tester,
  ) async {
    await _open(tester, _FakeAuthService(), canChangePassword: false);

    expect(find.text('Cambiar contraseña'), findsNothing);
    expect(find.byType(PasswordRequirements), findsNothing);
  });

  testWidgets('saves only the profile when the password is left empty', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await _open(tester, service);
    await _save(tester);
    await tester.pumpAndSettle();

    expect(service.calls, ['profile']);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('saves the profile and then the password, and closes', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await _open(tester, service);
    await _fillPassword(tester);
    await _save(tester);
    await tester.pumpAndSettle();

    expect(service.calls, ['profile', 'password']);
    expect(service.passwordRequest!.currentPassword, 'Old-Passw0rd!');
    expect(service.passwordRequest!.newPassword, _strong);
    expect(service.passwordRequest!.confirmPassword, _strong);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('does not call the network with a weak or mismatched password', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await _open(tester, service);

    await _fillPassword(tester, password: 'abc');
    await _save(tester);
    expect(service.calls, isEmpty);

    await _fillPassword(tester, confirmation: '${_strong}x');
    await _save(tester);
    expect(service.calls, isEmpty);
    expect(find.text('Las contraseñas no coinciden'), findsWidgets);

    await _type(tester, 'Contraseña actual', '');
    await _type(tester, 'Confirmar nueva contraseña', _strong);
    await _save(tester);
    expect(service.calls, isEmpty);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('keeps the form open when the password step fails', (
    tester,
  ) async {
    final service = _FakeAuthService()
      ..passwordError = const ApiException(
        'La contraseña actual es incorrecta.',
        statusCode: 400,
      );
    await _open(tester, service);
    await _type(tester, 'Primer nombre', 'Lucía');
    await _fillPassword(tester);
    await _save(tester);

    expect(service.calls, ['profile', 'password']);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(
      find.textContaining('Tus datos se guardaron, pero no se pudo cambiar'),
      findsOneWidget,
    );
  });

  testWidgets('hands back the saved profile when leaving after a failure', (
    tester,
  ) async {
    final service = _FakeAuthService()
      ..passwordError = const ApiException('Actual incorrecta.');
    await _open(tester, service);
    await _type(tester, 'Primer nombre', 'Lucía');
    await _fillPassword(tester);
    await _save(tester);
    // The error notification covers the app bar until it hides itself.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.result?.firstName, 'Lucía');
  });
}
