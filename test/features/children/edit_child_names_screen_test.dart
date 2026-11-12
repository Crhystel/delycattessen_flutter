import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_names_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/support/profile_test_support.dart';

final _child = Child(
  id: 3,
  firstName: 'Luis',
  lastName: 'Pérez',
  username: 'luisp',
  institutionName: 'Martim Cereré',
);

class _FakeChildService extends AuthService {
  ChildProfileUpdate? sent;
  ApiException? error;

  @override
  Future<Child> updateChildProfile(
    int studentId,
    ChildProfileUpdate data,
  ) async {
    sent = data;
    if (error != null) throw error!;
    return Child(
      id: studentId,
      firstName: data.names!.firstName.trim(),
      lastName: data.names!.lastName.trim(),
      username: 'luisp',
      institutionName: 'Martim Cereré',
    );
  }
}

Future<_FakeChildService> _open(
  WidgetTester tester, {
  _FakeChildService? service,
}) async {
  final fake = service ?? _FakeChildService();
  await openScreen(
    tester,
    EditChildNamesScreen(child: _child, authService: fake),
  );
  return fake;
}

void main() {
  testWidgets('shows only the four name fields, no username', (tester) async {
    await _open(tester);

    expect(find.text('Primer nombre'), findsOneWidget);
    expect(find.text('Segundo apellido'), findsOneWidget);
    expect(find.text('Usuario'), findsNothing);
    expect(find.text('Guardar cambios'), findsOneWidget);
  });

  testWidgets('sends only the names and pops with the updated child', (
    tester,
  ) async {
    final service = await _open(tester);

    await typeInto(tester, 'Primer nombre', 'Mateo');
    await tapButton(tester, 'Guardar cambios');
    await tester.pumpAndSettle();

    expect(service.sent!.names!.firstName, 'Mateo');
    expect(service.sent!.username, isNull);
    expect((hostOf(tester).result as Child).firstName, 'Mateo');
  });

  testWidgets('does not call the network without a first name', (tester) async {
    final service = await _open(tester);

    await typeInto(tester, 'Primer nombre', '');
    await tapButton(tester, 'Guardar cambios');

    expect(service.sent, isNull);
    expect(find.byType(EditChildNamesScreen), findsOneWidget);
  });

  testWidgets('stays open with the message when the backend rejects it', (
    tester,
  ) async {
    final service = _FakeChildService()
      ..error = const ApiException('No se pudo guardar.', statusCode: 400);
    await _open(tester, service: service);

    await tapButton(tester, 'Guardar cambios');

    expect(find.byType(EditChildNamesScreen), findsOneWidget);
    expect(find.text('No se pudo guardar.'), findsOneWidget);
  });
}
