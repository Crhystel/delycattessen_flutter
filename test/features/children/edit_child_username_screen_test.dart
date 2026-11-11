import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_username_screen.dart';
import 'package:flutter/material.dart';
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

  @override
  Future<Child> updateChildProfile(
    int studentId,
    ChildProfileUpdate data,
  ) async {
    sent = data;
    return Child(
      id: studentId,
      firstName: 'Luis',
      lastName: 'Pérez',
      username: data.username!.trim(),
      institutionName: 'Martim Cereré',
    );
  }
}

Future<_FakeChildService> _open(WidgetTester tester) async {
  final fake = _FakeChildService();
  await openScreen(
    tester,
    EditChildUsernameScreen(child: _child, authService: fake),
  );
  return fake;
}

void main() {
  testWidgets('shows only the username field, no names', (tester) async {
    await _open(tester);

    expect(find.text('Usuario'), findsWidgets);
    expect(find.text('Primer nombre'), findsNothing);
    expect(find.text('Guardar usuario'), findsOneWidget);
  });

  testWidgets('sends only the username and pops with the updated child', (
    tester,
  ) async {
    final service = await _open(tester);

    await tester.enterText(find.byType(TextField), 'luis.nuevo');
    await tapButton(tester, 'Guardar usuario');
    await tester.pumpAndSettle();

    expect(service.sent!.username, 'luis.nuevo');
    expect(service.sent!.names, isNull);
    expect((hostOf(tester).result as Child).username, 'luis.nuevo');
  });

  testWidgets('does not call the network with an empty username or spaces', (
    tester,
  ) async {
    final service = await _open(tester);

    await tester.enterText(find.byType(TextField), '');
    await tapButton(tester, 'Guardar usuario');
    await tester.enterText(find.byType(TextField), 'luis p');
    await tapButton(tester, 'Guardar usuario');

    expect(service.sent, isNull);
    expect(find.byType(EditChildUsernameScreen), findsOneWidget);
  });
}
