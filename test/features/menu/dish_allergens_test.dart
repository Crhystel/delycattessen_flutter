import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/utils/dish_allergens.dart';
import 'package:flutter_test/flutter_test.dart';

MenuDish _dish({
  List<String> allergens = const ['Maní', 'Lácteos'],
  List<String> conflicts = const [],
  bool flag = false,
}) => MenuDish(
  id: 1,
  name: 'Plato',
  description: '',
  price: 2,
  allergens: allergens,
  conflictingAllergens: conflicts,
  hasStudentAllergens: flag,
);

void main() {
  test('without conflicts nor flag there is no conflict', () {
    final advisory = dishAdvisory(_dish());

    expect(advisory.hasConflict, isFalse);
    expect(advisory.allergens, ['Maní', 'Lácteos']);
  });

  test('uses the conflicting allergens the backend lists', () {
    final advisory = dishAdvisory(
      _dish(conflicts: ['Maní'], flag: true),
      audience: const AllergenAudience.named('Ana'),
    );

    expect(advisory.conflicts, ['Maní']);
    expect(advisory.audience, const AllergenAudience.named('Ana'));
  });

  test('with only the flag every allergen of the dish is a conflict', () {
    final advisory = dishAdvisory(_dish(flag: true));

    expect(advisory.conflicts, ['Maní', 'Lácteos']);
  });

  test('a conflict missing from the dish allergens is listed there too', () {
    final advisory = dishAdvisory(
      _dish(allergens: ['Lácteos'], conflicts: ['Gluten']),
    );

    expect(advisory.allergens, containsAll(['Lácteos', 'Gluten']));
  });

  test('the audience defaults to unknown', () {
    expect(dishAdvisory(_dish()).audience, AllergenAudience.unknown);
  });
}
