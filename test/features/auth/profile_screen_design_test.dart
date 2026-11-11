import 'package:delycattessen_flutter/features/auth/screens/profile_screen.dart';
import 'package:delycattessen_flutter/features/auth/widgets/initials_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/profile_test_support.dart';

void main() {
  testWidgets('shows the header, a solid avatar and the logout', (
    tester,
  ) async {
    var logouts = 0;
    await openScreen(
      tester,
      ProfileScreen(
        me: testMe(role: 'PARENT'),
        authService: FakeAuthService(),
        extraSections: const Text('Mis hijos'),
        onLogout: () => logouts++,
      ),
    );

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Mis hijos'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);

    final avatar = tester.widget<InitialsAvatar>(find.byType(InitialsAvatar));
    expect(avatar.solid, isTrue);
    expect(avatar.radius, 32);

    await tester.tap(find.text('Cerrar sesión'));
    expect(logouts, 1);
  });

  testWidgets('a teacher gets the same profile: header, solid avatar, health '
      'section and logout', (tester) async {
    var logouts = 0;
    await openScreen(
      tester,
      ProfileScreen(
        me: testMe(role: 'TEACHER'),
        authService: FakeAuthService(),
        onOpenAllergies: () {},
        onLogout: () => logouts++,
      ),
    );

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Salud'), findsOneWidget);
    expect(find.text('Alergias'), findsOneWidget);
    expect(find.text('Mis hijos'), findsNothing);
    expect(
      tester.widget<InitialsAvatar>(find.byType(InitialsAvatar)).solid,
      isTrue,
    );

    await tester.tap(find.text('Cerrar sesión'));
    expect(logouts, 1);
  });

  testWidgets('without onLogout there is no logout button', (tester) async {
    await openScreen(
      tester,
      ProfileScreen(me: testMe(), authService: FakeAuthService()),
    );

    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('rows still open their screens', (tester) async {
    await openScreen(
      tester,
      ProfileScreen(
        me: testMe(role: 'PARENT'),
        authService: FakeAuthService(),
      ),
    );

    await tester.tap(find.text('Contraseña'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
  });
}
