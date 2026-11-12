import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/utils/catalog_allergens.dart';
import 'package:flutter_test/flutter_test.dart';

MenuItem _product(int id, List<Allergen> allergens) => MenuItem(
  id: id,
  name: 'P$id',
  description: '',
  price: 1,
  category: 'X',
  ingredients: const [],
  allergens: allergens,
);

final _gluten = Allergen(id: 1, name: 'Gluten');
final _milk = Allergen(id: 2, name: 'Lácteos');
final _nuts = Allergen(id: 3, name: 'Maní');

Combo _combo(List<ComboItem> items) => Combo(
  id: 7,
  name: 'Combo',
  price: 3,
  regularPrice: 4,
  endDate: DateTime(2026, 12, 31),
  items: items,
);

void main() {
  group('productAdvisory', () {
    test('splits the allergens of the product from the ones of the user', () {
      final advisory = productAdvisory(
        _product(1, [_gluten, _milk]),
        userAllergenIds: {2, 99},
        audience: const AllergenAudience.named('Ana'),
      );

      expect(advisory.allergens, ['Gluten', 'Lácteos']);
      expect(advisory.conflicts, ['Lácteos']);
      expect(advisory.hasConflict, isTrue);
      expect(advisory.audience, const AllergenAudience.named('Ana'));
    });

    test('has no conflict when the user has none of them', () {
      final advisory = productAdvisory(
        _product(1, [_gluten]),
        userAllergenIds: const {},
        audience: AllergenAudience.self,
      );

      expect(advisory.hasConflict, isFalse);
      expect(advisory.allergens, ['Gluten']);
    });

    test('a product without allergens has an empty advisory', () {
      final advisory = productAdvisory(
        _product(1, const []),
        userAllergenIds: {1},
        audience: AllergenAudience.self,
      );

      expect(advisory.allergens, isEmpty);
      expect(advisory.hasConflict, isFalse);
    });
  });

  group('comboAdvisory', () {
    test('joins the allergens the combo reports with the catalog ones', () {
      final combo = _combo(const [
        ComboItem(
          productId: 1,
          name: 'P1',
          quantity: 1,
          allergens: ['Gluten'],
          conflictingAllergens: ['Gluten'],
        ),
        ComboItem(productId: 2, name: 'P2', quantity: 1),
      ]);

      final advisory = comboAdvisory(
        combo,
        itemsById: {
          2: _product(2, [_nuts, _milk]),
        },
        userAllergenIds: {3},
        audience: const AllergenAudience.named('Ana'),
      );

      expect(advisory.allergens, ['Gluten', 'Maní', 'Lácteos']);
      // One from the backend, one completed by id from the catalog.
      expect(advisory.conflicts, ['Gluten', 'Maní']);
    });

    test('works without the catalog products', () {
      final combo = _combo(const [
        ComboItem(productId: 1, name: 'P1', quantity: 1, allergens: ['Gluten']),
      ]);

      final advisory = comboAdvisory(
        combo,
        itemsById: const {},
        userAllergenIds: {1},
        audience: AllergenAudience.self,
      );

      expect(advisory.allergens, ['Gluten']);
      expect(advisory.hasConflict, isFalse);
    });
  });

  test('combosIncluding keeps the combos that have the product', () {
    final withCola = _combo(const [
      ComboItem(productId: 2, name: 'Cola', quantity: 1),
    ]);
    final other = Combo(
      id: 8,
      name: 'Otro',
      price: 1,
      regularPrice: 1,
      endDate: DateTime(2026, 12, 31),
      items: const [ComboItem(productId: 5, name: 'X', quantity: 1)],
    );

    expect(combosIncluding(2, [other, withCola]), [withCola]);
    expect(combosIncluding(9, [other, withCola]), isEmpty);
  });
}
