import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/models/parental_control_model.dart';
import 'package:delycattessen_flutter/features/children/providers/child_settings_controller.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_names_screen.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_password_screen.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_username_screen.dart';
import 'package:delycattessen_flutter/features/children/screens/edit_child_screen.dart';
import 'package:delycattessen_flutter/features/children/services/parental_control_service.dart';
import 'package:delycattessen_flutter/features/users/models/allergy_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _child = Child(
  id: 3,
  firstName: 'Pepito',
  secondName: 'Alejandro',
  lastName: 'Pérez',
  secondLastName: 'Pérez',
  username: 'pepito123',
  institutionName: 'Martin Cerere',
);

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.allergies = const []});

  final List<Allergen> allergies;

  @override
  Future<List<Allergen>> getStudentAllergies(int studentId) async => allergies;
}

class _FakeParentalService extends ParentalControlService {
  @override
  Future<ParentalControl> getParentalControl(int studentId) async =>
      ParentalControl(
        dailyLimitEnabled: true,
        dailyLimitAmount: 1,
        allowedDaysEnabled: false,
        allowedDays: const [],
        lowBalanceAlertEnabled: true,
        lowBalanceAlertAmount: 2,
      );
}

Future<void> _open(WidgetTester tester, {List<Allergen>? allergies}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = _FakeAuthService(
    allergies: allergies ?? [Allergen(id: 1, name: 'Sulfitos')],
  );
  final settings = ChildSettingsController(
    studentId: _child.id,
    authService: auth,
    parentalService: _FakeParentalService(),
  );
  addTearDown(settings.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: EditChildScreen(
        child: _child,
        authService: auth,
        settings: settings,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('is a menu: profile card, Cuenta and Configuración', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Datos de tu hijo/a'), findsOneWidget);
    expect(find.text('Pepito Pérez'), findsOneWidget);
    expect(find.text('Martin Cerere'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);
    expect(find.text('Pepito Alejandro Pérez Pérez'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('pepito123 · con este inicia sesión'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
    // The form moved to its own screen.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Guardar cambios'), findsNothing);
  });

  testWidgets('summarizes the parental control and the allergies', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Control parental'), findsOneWidget);
    expect(find.text('Límite \$1.00/día · aviso bajo \$2.00'), findsOneWidget);
    expect(find.text('Alergias'), findsOneWidget);
    expect(find.text('Sulfitos'), findsOneWidget);
  });

  testWidgets('shows a camera badge to change the photo', (tester) async {
    await _open(tester);

    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
  });

  testWidgets('each account row opens its own screen', (tester) async {
    await _open(tester);
    expect(find.text('Contraseña'), findsOneWidget);

    Future<void> openAndBack(String row, Type screen) async {
      await tester.tap(find.text(row).first);
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
    }

    await openAndBack('Nombres', EditChildNamesScreen);
    await openAndBack('Usuario', EditChildUsernameScreen);
    await openAndBack('Contraseña', EditChildPasswordScreen);
  });
}
