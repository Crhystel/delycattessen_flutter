import 'package:delycattessen_flutter/features/auth/screens/change_email_screen.dart';
import 'package:delycattessen_flutter/features/auth/screens/edit_names_screen.dart';
import 'package:delycattessen_flutter/features/auth/screens/profile_password_screen.dart';
import 'package:delycattessen_flutter/features/auth/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/profile_test_support.dart';

void main() {
  testWidgets('shows who is signed in and one arrow row per option', (
    tester,
  ) async {
    final me = testMe();
    await openScreen(
      tester,
      ProfileScreen(me: me, authService: FakeAuthService()),
    );

    expect(find.text('Ana Pérez'), findsOneWidget); // summary
    expect(find.text('Nombres'), findsOneWidget);
    expect(find.text('Ana Lucía Pérez Mora'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('docente@mail.com'), findsWidgets);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    // Nothing of the forms is shown until the user presses an arrow.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Guardar cambios'), findsNothing);
  });

  testWidgets('has no allergies row unless the caller provides it', (
    tester,
  ) async {
    await openScreen(tester, ProfileScreen(me: testMe()));

    expect(find.text('Alergias'), findsNothing);
  });

  testWidgets('shows the allergies row and runs the callback', (tester) async {
    var opened = 0;
    await openScreen(
      tester,
      ProfileScreen(me: testMe(), onOpenAllergies: () => opened++),
    );

    expect(find.text('Salud'), findsOneWidget);
    await tester.tap(find.text('Alergias'));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('each arrow opens its own screen', (tester) async {
    await openScreen(
      tester,
      ProfileScreen(me: testMe(), authService: FakeAuthService()),
    );

    final cases = <String, Type>{
      'Nombres': EditNamesScreen,
      'Correo': ChangeEmailScreen,
      'Contraseña': ProfilePasswordScreen,
    };
    for (final entry in cases.entries) {
      await tester.tap(find.text(entry.key).first);
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    }
  });

  testWidgets('refreshes the summary and hands back the updated profile', (
    tester,
  ) async {
    final service = FakeAuthService();
    await openScreen(tester, ProfileScreen(me: testMe(), authService: service));

    await tester.tap(find.text('Nombres'));
    await tester.pumpAndSettle();
    await typeInto(tester, 'Primer nombre', 'Lucía');
    await tapButton(tester, 'Guardar cambios');
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Lucía Pérez'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final host = hostOf(tester);
    expect(host.popped, isTrue);
    expect((host.result as dynamic).firstName, 'Lucía');
  });

  testWidgets('leaves with no result when nothing changed', (tester) async {
    await openScreen(
      tester,
      ProfileScreen(me: testMe(), authService: FakeAuthService()),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(hostOf(tester).popped, isTrue);
    expect(hostOf(tester).result, isNull);
  });
}
