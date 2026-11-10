import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/auth/screens/edit_names_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/profile_test_support.dart';

void main() {
  testWidgets('shows the current names', (tester) async {
    await openScreen(
      tester,
      EditNamesScreen(me: testMe(), authService: FakeAuthService()),
    );

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Lucía'), findsOneWidget);
    expect(find.text('Pérez'), findsOneWidget);
    expect(find.text('Mora'), findsOneWidget);
  });

  testWidgets('saves the names with the current email and no password', (
    tester,
  ) async {
    final service = FakeAuthService();
    await openScreen(
      tester,
      EditNamesScreen(me: testMe(), authService: service),
    );

    await typeInto(tester, 'Primer nombre', 'Mateo');
    await tapButton(tester, 'Guardar cambios');
    await tester.pumpAndSettle();

    expect(service.calls, ['profile']);
    expect(service.lastProfile!.names.firstName, 'Mateo');
    expect(service.lastProfile!.email, 'docente@mail.com');
    expect(
      service.lastProfile!.toJson().containsKey('current_password'),
      false,
    );
    expect(hostOf(tester).popped, isTrue);
    expect((hostOf(tester).result as dynamic).firstName, 'Mateo');
  });

  testWidgets('does not call the network without a first name', (tester) async {
    final service = FakeAuthService();
    await openScreen(
      tester,
      EditNamesScreen(me: testMe(), authService: service),
    );

    await typeInto(tester, 'Primer nombre', '');
    await tapButton(tester, 'Guardar cambios');

    expect(service.calls, isEmpty);
    expect(find.byType(EditNamesScreen), findsOneWidget);
  });

  testWidgets('stays open with the message when the backend rejects it', (
    tester,
  ) async {
    final service = FakeAuthService()
      ..profileError = const ApiException('No se pudo guardar el perfil.');
    await openScreen(
      tester,
      EditNamesScreen(me: testMe(), authService: service),
    );

    await tapButton(tester, 'Guardar cambios');

    expect(service.calls, ['profile']);
    expect(find.byType(EditNamesScreen), findsOneWidget);
    expect(find.text('No se pudo guardar el perfil.'), findsOneWidget);
  });
}
