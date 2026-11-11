import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/menu/services/product_catalog_source.dart';
import 'package:delycattessen_flutter/features/users/models/allergy_models.dart';
import 'package:delycattessen_flutter/features/users/services/allergy_owner.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth extends AuthService {
  _FakeAuth({this.allergies = const [], this.fail = false});

  final List<Allergen> allergies;
  final bool fail;

  @override
  Future<List<Allergen>> getOwnStudentAllergies() async {
    if (fail) throw Exception('sin conexión');
    return allergies;
  }
}

void main() {
  group('StudentSelfAllergyOwner', () {
    test('loads the student\'s own allergies', () async {
      final owner = StudentSelfAllergyOwner(
        authService: _FakeAuth(
          allergies: [
            Allergen(id: 3, name: 'Sulfitos'),
            Allergen(id: 7, name: 'Sésamo'),
          ],
        ),
      );

      final loaded = await owner.load();

      expect(loaded.map((a) => a.name), ['Sulfitos', 'Sésamo']);
    });

    test('is read-only: only the parent edits a student\'s allergies', () {
      final owner = StudentSelfAllergyOwner(authService: _FakeAuth());

      expect(() => owner.save([1]), throwsUnsupportedError);
    });
  });

  group('OwnCatalogSource.student', () {
    test('marks the catalog with the student\'s own allergen ids', () async {
      final source = OwnCatalogSource.student(
        allergyOwner: StudentSelfAllergyOwner(
          authService: _FakeAuth(
            allergies: [Allergen(id: 3, name: 'Sulfitos')],
          ),
        ),
      );

      expect(await source.loadAllergenIds(), {3});
    });

    test('fails (instead of showing an unmarked catalog) when the allergies '
        'cannot be loaded', () async {
      final source = OwnCatalogSource.student(
        allergyOwner: StudentSelfAllergyOwner(
          authService: _FakeAuth(fail: true),
        ),
      );

      expect(source.loadAllergenIds(), throwsException);
    });
  });
}
