import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

void main() {
  group('Combo savings', () {
    test('is the regular price minus the combo price', () {
      final combo = lunchCombo();

      expect(combo.hasSavings, isTrue);
      expect(combo.savings, closeTo(0.50, 1e-9));
    });

    test('is zero when the combo is not cheaper', () {
      final combo = Combo(
        id: 1,
        name: 'Igual',
        price: 4.00,
        regularPrice: 3.00,
        endDate: DateTime(2026, 12, 31),
      );

      expect(combo.hasSavings, isFalse);
      expect(combo.savings, 0.0);
    });
  });

  group('Combo stock', () {
    Map<String, dynamic> json({Object? available = 6, Object? itemStock = 9}) =>
        {
          'id': 3,
          'name': 'Combo',
          'price': '3.50',
          'regular_price': '4.00',
          'end_date': '2026-12-31',
          'available_quantity': available,
          'items': [
            {
              'product_id': 1,
              'name': 'Sánduche',
              'quantity': 1,
              'stock': itemStock,
              'is_active': true,
            },
          ],
        };

    test('reads available_quantity and the stock of each item', () {
      final combo = Combo.fromJson(json());

      expect(combo.availableQuantity, 6);
      expect(combo.isAvailable, isTrue);
      expect(combo.items.single.stock, 9);
    });

    test('without the new fields the combo is available, as before', () {
      final combo = Combo.fromJson({
        'id': 3,
        'name': 'Combo',
        'price': '3.50',
        'items': [
          {'product_id': 1, 'name': 'Sánduche', 'quantity': 1},
        ],
      });

      expect(combo.availableQuantity, isNull);
      expect(combo.isAvailable, isTrue);
      expect(combo.items.single.stock, isNull);
    });

    test('available_quantity zero means sold out', () {
      final combo = Combo.fromJson(json(available: 0, itemStock: 0));

      expect(combo.availableQuantity, 0);
      expect(combo.isAvailable, isFalse);
      expect(combo.items.single.stock, 0);
    });

    test('unreadable values are ignored instead of failing the combo', () {
      final combo = Combo.fromJson(json(available: 'muchos', itemStock: null));

      expect(combo.availableQuantity, isNull);
      expect(combo.isAvailable, isTrue);
      expect(combo.items.single.stock, isNull);
    });

    test('visibleCombos leaves out only the sold out ones', () {
      final offers = CatalogOffers(
        combos: [
          Combo.fromJson({...json(available: 0), 'id': 1}),
          Combo.fromJson({...json(available: 3), 'id': 2}),
          Combo.fromJson({...json()..remove('available_quantity'), 'id': 4}),
        ],
      );

      expect(offers.combos.length, 3);
      expect(offers.visibleCombos.map((c) => c.id), [2, 4]);
    });
  });
}
