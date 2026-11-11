import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/users/models/allergy_models.dart';
import 'package:delycattessen_flutter/features/users/screens/allergy_management_screen.dart';
import 'package:delycattessen_flutter/features/users/services/allergy_owner.dart';
import 'package:delycattessen_flutter/features/users/widgets/parent_allergy_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  bool failLoading = false;

  @override
  Future<List<Allergen>> getAllergens() async {
    if (failLoading) throw Exception('sin red');
    return [
      Allergen(id: 1, name: 'Sulfitos'),
      Allergen(id: 2, name: 'Sésamo'),
      Allergen(id: 3, name: 'Maní'),
    ];
  }
}

class _FakeOwner implements AllergyOwner {
  List<int>? saved;

  @override
  Future<List<Allergen>> load() async => [Allergen(id: 1, name: 'Sulfitos')];

  @override
  Future<List<String>> save(List<int> allergenIds) async {
    saved = allergenIds;
    return [];
  }
}

Future<_FakeOwner> _pump(
  WidgetTester tester, {
  bool parentStyle = false,
  _FakeAuthService? service,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final owner = _FakeOwner();
  await tester.pumpWidget(
    MaterialApp(
      home: AllergyManagementScreen(
        owner: owner,
        personName: 'Pepito Pérez',
        parentStyle: parentStyle,
        authService: service ?? _FakeAuthService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return owner;
}

void main() {
  group('teacher style (default)', () {
    testWidgets('keeps the app bar title and the red-free chips', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Alergias de Pepito Pérez'), findsOneWidget);
      expect(find.byType(ParentAllergyForm), findsNothing);
      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });
  });

  group('parentStyle', () {
    testWidgets('shows the subpage header with the child name', (tester) async {
      await _pump(tester, parentStyle: true);

      expect(find.text('Alergias'), findsOneWidget);
      expect(find.text('Pepito Pérez'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(InputChip), findsNothing);
      expect(find.text('Registradas'), findsOneWidget);
      expect(find.text('Sulfitos'), findsOneWidget);
      expect(find.text('Añadir una alergia'), findsOneWidget);
      expect(find.text('Selecciona una alergia'), findsOneWidget);
      expect(find.textContaining('cuando pidas para Pepito.'), findsOneWidget);
    });

    testWidgets('adds an allergen from the selector and removes a chip', (
      tester,
    ) async {
      await _pump(tester, parentStyle: true);

      ElevatedButton addButton() =>
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(addButton().onPressed, isNull);

      await tester.tap(find.byType(DropdownButton<Allergen>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sésamo').last);
      await tester.pumpAndSettle();
      expect(addButton().onPressed, isNotNull);

      await tester.tap(find.text('Añadir'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget); // contador
      expect(find.text('Sésamo'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Quitar sulfitos'));
      await tester.pumpAndSettle();
      expect(find.text('Sulfitos'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('saves the registered allergens and pops with true', (
      tester,
    ) async {
      final owner = await _pump(tester, parentStyle: true);

      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(owner.saved, [1]);
    });

    testWidgets('shows a retry state when loading fails, keeping the header', (
      tester,
    ) async {
      await _pump(
        tester,
        parentStyle: true,
        service: _FakeAuthService()..failLoading = true,
      );

      expect(find.text('No pudimos cargar las alergias'), findsOneWidget);
      expect(find.text('Alergias'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsNothing);
    });
  });
}
