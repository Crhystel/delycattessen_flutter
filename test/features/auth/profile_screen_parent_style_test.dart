import 'package:delycattessen_flutter/features/auth/screens/profile_screen.dart';
import 'package:delycattessen_flutter/features/auth/widgets/initials_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/profile_test_support.dart';

void main() {
  testWidgets('parentStyle shows the header, a solid avatar and the logout', (
    tester,
  ) async {
    var logouts = 0;
    await openScreen(
      tester,
      ProfileScreen(
        me: testMe(role: 'PARENT'),
        authService: FakeAuthService(),
        parentStyle: true,
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

  testWidgets('without parentStyle it keeps the app bar and the soft avatar', (
    tester,
  ) async {
    await openScreen(
      tester,
      ProfileScreen(me: testMe(), authService: FakeAuthService()),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(
      tester.widget<InitialsAvatar>(find.byType(InitialsAvatar)).solid,
      isFalse,
    );
  });

  testWidgets('parentStyle rows still open their screens', (tester) async {
    await openScreen(
      tester,
      ProfileScreen(
        me: testMe(role: 'PARENT'),
        authService: FakeAuthService(),
        parentStyle: true,
      ),
    );

    await tester.tap(find.text('Contraseña'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
  });
}
