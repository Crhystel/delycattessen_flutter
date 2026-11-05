import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/screens/change_password_screen.dart';
import 'package:delycattessen_flutter/features/auth/screens/edit_profile_screen.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/auth/widgets/new_password_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _teacher = MeResponse(
  id: 7,
  email: 'docente@mail.com',
  firstName: 'Ana',
  lastName: 'Pérez',
  role: 'TEACHER',
  hasChildren: false,
  hasPaymentPin: false,
  mustChangePassword: false,
);

Future<void> _pump(WidgetTester tester, {required bool canChangePassword}) {
  return tester.pumpWidget(
    MaterialApp(
      home: EditProfileScreen(
        me: _teacher,
        canChangePassword: canChangePassword,
        authService: AuthService(),
      ),
    ),
  );
}

void main() {
  testWidgets('offers the password change when it is allowed', (tester) async {
    await _pump(tester, canChangePassword: true);

    expect(find.text('Cambiar contraseña'), findsOneWidget);
  });

  testWidgets('hides the password change by default', (tester) async {
    await _pump(tester, canChangePassword: false);

    expect(find.text('Cambiar contraseña'), findsNothing);
  });

  testWidgets('opens the reusable password form', (tester) async {
    await _pump(tester, canChangePassword: true);
    await tester.ensureVisible(find.text('Cambiar contraseña'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.lock_outline));
    // The auth layout keeps an animation running, so it never "settles":
    // pump the route transition by hand.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.byType(NewPasswordFields), findsOneWidget);
  });
}
