import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/screens/profile_screen.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/children/widgets/profile_children_section.dart';
import 'package:delycattessen_flutter/features/users/models/allergy_models.dart';
import 'package:delycattessen_flutter/features/users/screens/allergy_management_screen.dart';
import 'package:delycattessen_flutter/features/users/services/allergy_owner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/profile_test_support.dart';

const _sizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 390x844': Size(390, 844),
  'tablet 768x1024': Size(768, 1024),
};

const _longName = 'Maria Fernanda Alexandra Villavicencio Zambrano';

class _ChildrenService extends AuthService {
  @override
  Future<List<Child>> getChildren() async => [
    Child(
      id: 1,
      firstName: _longName,
      lastName: 'Pérez',
      institutionName: 'Unidad Educativa Particular Bilingue Martim Cerere',
    ),
    Child(id: 2, firstName: 'Ana', lastName: 'Mora', institutionName: 'Sauce'),
  ];

  @override
  Future<List<Allergen>> getAllergens() async => [
    for (var i = 0; i < 8; i++) Allergen(id: i, name: 'Alérgeno largo $i'),
  ];
}

class _Owner implements AllergyOwner {
  @override
  Future<List<Allergen>> load() async => [
    for (var i = 0; i < 5; i++) Allergen(id: i, name: 'Alérgeno largo $i'),
  ];

  @override
  Future<List<String>> save(List<int> allergenIds) async => [];
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget home,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in _sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      final label = '${entry.key}, text x$scale';

      testWidgets('parent profile with children fits: $label', (tester) async {
        final provider = ChildrenProvider(authService: _ChildrenService());
        await provider.ensureLoaded();
        await _pump(
          tester,
          entry.value,
          scale,
          ChangeNotifierProvider.value(
            value: provider,
            child: ProfileScreen(
              me: testMe(role: 'PARENT'),
              parentStyle: true,
              extraSections: const ProfileChildrenSection(),
              onLogout: () {},
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Añadir hijo/a'), findsOneWidget);
      });

      testWidgets('parent allergies fit: $label', (tester) async {
        await _pump(
          tester,
          entry.value,
          scale,
          AllergyManagementScreen(
            owner: _Owner(),
            personName: _longName,
            parentStyle: true,
            authService: _ChildrenService(),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Guardar cambios'), findsOneWidget);
      });
    }
  }
}
