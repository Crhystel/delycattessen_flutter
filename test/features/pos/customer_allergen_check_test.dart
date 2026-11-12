import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/pos/utils/customer_allergen_check.dart';
import 'package:flutter_test/flutter_test.dart';

MenuItem _item(int id, List<String> allergens) => MenuItem(
  id: id,
  name: 'Producto $id',
  description: '',
  price: 2.0,
  category: 'Snacks',
  ingredients: const [],
  allergens: [
    for (var i = 0; i < allergens.length; i++)
      Allergen(id: id * 10 + i, name: allergens[i]),
  ],
  stock: 5,
);

Combo _combo(List<ComboItem> items) => Combo(
  id: 1,
  name: 'Combo',
  price: 3,
  regularPrice: 4,
  endDate: DateTime(2026, 12, 31),
  items: items,
);

void main() {
  final check = CustomerAllergenCheck(
    customerName: 'Pepito Pérez',
    allergies: [' Gluten ', 'sulfitos', ''],
  );

  group('products', () {
    test('conflicts ignore case and spaces and keep the product spelling', () {
      final item = _item(1, ['GLUTEN', 'Lácteos']);

      expect(check.productConflicts(item), ['GLUTEN']);
    });

    test('no allergen in common: no conflict', () {
      expect(check.productConflicts(_item(1, ['Lácteos'])), isEmpty);
      expect(check.productConflicts(_item(2, const [])), isEmpty);
    });

    test('advisory names the customer and lists every allergen', () {
      final advisory = check.productAdvisory(_item(1, ['Gluten', 'Lácteos']));

      expect(advisory.allergens, ['Gluten', 'Lácteos']);
      expect(advisory.conflicts, ['Gluten']);
      expect(advisory.hasConflict, isTrue);
      expect(advisory.blockedLabel, 'No disponible para Pepito Pérez');
    });
  });

  group('combos', () {
    test('uses the allergens the combo lists, even for absent products', () {
      final combo = _combo(const [
        ComboItem(
          productId: 9,
          name: 'Agotado',
          quantity: 1,
          allergens: ['Sulfitos'],
        ),
      ]);

      expect(check.comboConflicts(combo, const {}), ['Sulfitos']);
    });

    test('also checks the catalog products by name, without repeats', () {
      final combo = _combo(const [
        ComboItem(productId: 1, name: 'A', quantity: 1, allergens: ['Gluten']),
        ComboItem(productId: 2, name: 'B', quantity: 1),
      ]);
      final catalog = {
        1: _item(1, ['gluten']),
        2: _item(2, ['Sulfitos', 'Soya']),
      };

      expect(check.comboConflicts(combo, catalog), ['Gluten', 'Sulfitos']);
      final advisory = check.comboAdvisory(combo, catalog);
      expect(advisory.allergens, ['Gluten', 'Sulfitos', 'Soya']);
      expect(advisory.conflicts, ['Gluten', 'Sulfitos']);
    });

    test('ignores the conflicts the backend computes for the cashier', () {
      final combo = _combo(const [
        ComboItem(
          productId: 1,
          name: 'A',
          quantity: 1,
          allergens: ['Lácteos'],
          conflictingAllergens: ['Lácteos'],
        ),
      ]);

      expect(check.comboConflicts(combo, const {}), isEmpty);
    });
  });

  group('without a customer', () {
    final anonymous = CustomerAllergenCheck.forUser(null);

    test('nothing conflicts and the audience is unknown', () {
      final advisory = anonymous.productAdvisory(_item(1, ['Gluten']));

      expect(anonymous.productConflicts(_item(1, ['Gluten'])), isEmpty);
      expect(advisory.audience, AllergenAudience.unknown);
      expect(advisory.allergens, ['Gluten']);
      expect(advisory.showsBoxes, isFalse);
      expect(advisory.hasConflict, isFalse);
    });
  });
}
