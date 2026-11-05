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

  test('Promotion.fromJson keeps the ids of the products on offer', () {
    final promotion = Promotion.fromJson({
      'id': 5,
      'discount_percentage': 15,
      'end_date': '2026-12-31',
      'image': null,
      'products': [
        {'id': 7, 'name': 'Jugo', 'price': '1.00', 'image': null},
        {'id': 9, 'name': 'Galleta', 'price': '0.50', 'image': null},
      ],
    });

    expect(promotion.productIds, [7, 9]);
    expect(promotion.productNames, ['Jugo', 'Galleta']);
  });
}
