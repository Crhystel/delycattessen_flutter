import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:flutter_test/flutter_test.dart';

AllergenAdvisory _advisory(
  List<String> conflicts, {
  AllergenAudience audience = const AllergenAudience.named('Pepito'),
  List<String>? allergens,
}) => AllergenAdvisory.of(
  allergens: allergens ?? ['Gluten', 'Sulfitos', 'Lácteos'],
  conflicts: conflicts,
  audience: audience,
);

void main() {
  group('conflict title', () {
    test('one allergen: "Contiene sulfitos"', () {
      expect(_advisory(['Sulfitos']).conflictTitle, 'Contiene sulfitos');
    });

    test('two allergens: "Contiene gluten y lácteos"', () {
      expect(
        _advisory(['Gluten', 'Lácteos']).conflictTitle,
        'Contiene gluten y lácteos',
      );
    });

    test('three allergens: commas and a final "y"', () {
      expect(
        _advisory(['Gluten', 'Sulfitos', 'Lácteos']).conflictTitle,
        'Contiene gluten, sulfitos y lácteos',
      );
    });
  });

  group('conflict body', () {
    test('named, one allergen, dish', () {
      expect(
        _advisory(['Sulfitos']).conflictBody(AllergenSubject.dish),
        'Pepito tiene registrada esta alergia, por eso este plato no se le '
        'puede vender.',
      );
    });

    test('named, several allergens, product', () {
      expect(
        _advisory(['Gluten', 'Lácteos']).conflictBody(AllergenSubject.product),
        'Pepito tiene registradas estas alergias, por eso este producto no se '
        'le puede vender.',
      );
    });

    test('self, one allergen, combo', () {
      expect(
        _advisory([
          'Sulfitos',
        ], audience: AllergenAudience.self).conflictBody(AllergenSubject.combo),
        'Tienes registrada esta alergia, por eso este combo no se te puede '
        'vender.',
      );
    });

    test('self, several allergens, dish', () {
      expect(
        _advisory([
          'Gluten',
          'Lácteos',
        ], audience: AllergenAudience.self).conflictBody(AllergenSubject.dish),
        'Tienes registradas estas alergias, por eso este plato no se te puede '
        'vender.',
      );
    });
  });

  group('safe message', () {
    test('named: one allergen in the item', () {
      expect(
        _advisory([], allergens: ['Gluten']).safeMessage,
        'Pepito no tiene registrada esta alergia.',
      );
    });

    test('named: several allergens in the item', () {
      expect(
        _advisory([]).safeMessage,
        'Pepito no tiene registradas estas alergias.',
      );
    });

    test('self', () {
      expect(
        _advisory([], audience: AllergenAudience.self).safeMessage,
        'No tienes registradas estas alergias.',
      );
    });
  });

  group('blocked label', () {
    test('named', () {
      expect(_advisory(['Gluten']).blockedLabel, 'No disponible para Pepito');
    });

    test('self', () {
      expect(
        _advisory(['Gluten'], audience: AllergenAudience.self).blockedLabel,
        'No disponible para ti',
      );
    });

    test('unknown', () {
      expect(
        _advisory(['Gluten'], audience: AllergenAudience.unknown).blockedLabel,
        'No disponible',
      );
    });
  });

  group('boxes and conflict flag', () {
    test('named and self audiences show the boxes', () {
      expect(_advisory([]).showsBoxes, isTrue);
      expect(_advisory([], audience: AllergenAudience.self).showsBoxes, isTrue);
    });

    test('an unknown audience gets only the chips', () {
      final advisory = _advisory([], audience: AllergenAudience.unknown);
      expect(advisory.showsBoxes, isFalse);
      expect(const AllergenAdvisory().showsBoxes, isFalse);
    });

    test('hasConflict follows the conflicts', () {
      expect(_advisory(['Gluten']).hasConflict, isTrue);
      expect(_advisory([]).hasConflict, isFalse);
    });

    test('an empty name is an unknown audience', () {
      expect(const AllergenAudience.named(''), AllergenAudience.unknown);
      expect(const AllergenAudience.named('Ana'), isNot(AllergenAudience.self));
    });
  });

  group('AllergenAdvisory.of', () {
    test('trims, drops blanks and repeats and keeps the order', () {
      final advisory = AllergenAdvisory.of(
        allergens: [' Gluten ', '', 'gluten', 'Lácteos'],
        conflicts: ['Lácteos', ' lácteos '],
      );
      expect(advisory.allergens, ['Gluten', 'Lácteos']);
      expect(advisory.conflicts, ['Lácteos']);
    });

    test('lists a conflict that is missing from the allergens', () {
      final advisory = AllergenAdvisory.of(
        allergens: ['Gluten'],
        conflicts: ['Sulfitos'],
      );
      expect(advisory.allergens, ['Gluten', 'Sulfitos']);
    });
  });
}
