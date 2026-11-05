import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _child = Child(
  id: 3,
  firstName: 'Luis',
  lastName: 'Pérez',
  username: 'luisp',
  institutionName: 'Martim Cereré',
);

class _FakeAuthService extends AuthService {
  ChildProfileUpdate? sent;

  @override
  Future<Child> updateChildProfile(
    int studentId,
    ChildProfileUpdate data,
  ) async {
    sent = data;
    return Child(
      id: studentId,
      firstName: data.names.firstName.trim(),
      lastName: data.names.lastName.trim(),
      username: data.username,
      institutionName: 'Martim Cereré',
    );
  }
}

Future<void> _open(WidgetTester tester, _FakeAuthService service) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: EditChildScreen(child: _child, authService: service),
    ),
  );
}

void main() {
  testWidgets('shows who is edited and the form in sections', (tester) async {
    await _open(tester, _FakeAuthService());

    expect(find.text('Luis Pérez'), findsOneWidget);
    expect(find.text('Martim Cereré'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);
    expect(find.text('Acceso'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
  });

  testWidgets('saves the edited names and closes the screen', (tester) async {
    final service = _FakeAuthService();
    await _open(tester, service);

    await tester.enterText(find.byType(TextField).first, 'Mateo');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(service.sent!.names.firstName, 'Mateo');
    expect(service.sent!.username, 'luisp');
  });
}
