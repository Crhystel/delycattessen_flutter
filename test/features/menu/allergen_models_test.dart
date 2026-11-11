import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _dish(Map<String, dynamic> extra) => {
  'id': 1,
  'name': 'Pollo asado',
  ...extra,
};

Combo _combo(List<Map<String, dynamic>> items) =>
    Combo.fromJson({'id': 7, 'name': 'Promo', 'price': '2.00', 'items': items});

void main() {
  group('MenuDish.conflictingAllergens', () {
    test('reads the names the backend marks as the viewer\'s', () {
      final dish = MenuDish.fromJson(
        _dish({
          'allergens': ['Sulfitos', 'Gluten'],
          'conflicting_allergens': ['Sulfitos'],
        }),
      );
      expect(dish.conflictingAllergens, ['Sulfitos']);
      expect(dish.allergens, ['Sulfitos', 'Gluten']);
    });

    test('is empty when the field is missing', () {
      expect(MenuDish.fromJson(_dish({})).conflictingAllergens, isEmpty);
    });

    test('is empty when the field is unreadable', () {
      expect(
        MenuDish.fromJson(
          _dish({'conflicting_allergens': 'Sulfitos'}),
        ).conflictingAllergens,
        isEmpty,
      );
      expect(
        MenuDish.fromJson(
          _dish({'conflicting_allergens': null}),
        ).conflictingAllergens,
        isEmpty,
      );
    });

    test('skips entries that are not names', () {
      final dish = MenuDish.fromJson(
        _dish({
          'conflicting_allergens': ['Gluten', 3, null, '', '  '],
        }),
      );
      expect(dish.conflictingAllergens, ['Gluten']);
    });

    test('the constructor keeps its old shape', () {
      final dish = MenuDish(id: 1, name: 'a', description: '', price: 1);
      expect(dish.conflictingAllergens, isEmpty);
    });
  });

  group('ComboItem allergens', () {
    test('reads {id, name} objects', () {
      final item = ComboItem.fromJson({
        'product_id': 1,
        'name': 'Crepes',
        'quantity': 1,
        'allergens': [
          {'id': 1, 'name': 'Gluten'},
          {'id': 2, 'name': 'Lácteos'},
        ],
        'conflicting_allergens': [
          {'id': 2, 'name': 'Lácteos'},
        ],
      });
      expect(item.allergens, ['Gluten', 'Lácteos']);
      expect(item.conflictingAllergens, ['Lácteos']);
    });

    test('accepts plain strings too', () {
      final item = ComboItem.fromJson({
        'allergens': ['Gluten'],
        'conflicting_allergens': ['Gluten'],
      });
      expect(item.allergens, ['Gluten']);
      expect(item.conflictingAllergens, ['Gluten']);
    });

    test('are empty when absent', () {
      final item = ComboItem.fromJson({'product_id': 1, 'name': 'Cola'});
      expect(item.allergens, isEmpty);
      expect(item.conflictingAllergens, isEmpty);
    });

    test('are empty when unreadable, without failing the item', () {
      final item = ComboItem.fromJson({
        'product_id': 1,
        'name': 'Cola',
        'allergens': 'Gluten',
        'conflicting_allergens': [
          {'id': 1},
          42,
        ],
      });
      expect(item.name, 'Cola');
      expect(item.allergens, isEmpty);
      expect(item.conflictingAllergens, isEmpty);
    });
  });

  group('Combo allergens', () {
    test('joins the allergens of its items without repeats, in order', () {
      final combo = _combo([
        {
          'product_id': 1,
          'name': 'Crepes',
          'allergens': ['Gluten', 'Lácteos'],
          'conflicting_allergens': ['Lácteos'],
        },
        {
          'product_id': 2,
          'name': 'Tostada',
          'allergens': ['gluten', 'Soya'],
          'conflicting_allergens': ['Soya', 'lácteos'],
        },
      ]);
      expect(combo.allergenNames, ['Gluten', 'Lácteos', 'Soya']);
      expect(combo.conflictingAllergens, ['Lácteos', 'Soya']);
    });

    test('are empty for items without allergen data', () {
      final combo = _combo([
        {'product_id': 1, 'name': 'Cola'},
      ]);
      expect(combo.allergenNames, isEmpty);
      expect(combo.conflictingAllergens, isEmpty);
    });

    test('are empty for a combo without items', () {
      expect(_combo([]).allergenNames, isEmpty);
    });
  });
}
