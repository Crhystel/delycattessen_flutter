import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> product({String? finalPrice, int? discount}) => {
    'id': 1,
    'name': 'Sandwich',
    'price': '2.50',
    'final_price': ?finalPrice,
    'discount_percentage': ?discount,
  };

  group('MenuItem.fromJson', () {
    test('reads the price', () {
      final item = MenuItem.fromJson(product());
      expect(item.price, 2.50);
    });

    test('ignores final_price and discount_percentage if still sent', () {
      final item = MenuItem.fromJson(product(finalPrice: '2.00', discount: 20));
      expect(item.price, 2.50);
    });
  });

  group('Combo.fromJson', () {
    test('reads price, regular price, image and products', () {
      final combo = Combo.fromJson({
        'id': 3,
        'name': 'Combo almuerzo',
        'price': '3.50',
        'regular_price': '4.00',
        'end_date': '2026-10-31',
        'image': 'http://127.0.0.1:8000/media/combo.jpg',
        'items': [
          {'product_id': 1, 'name': 'Sanduche', 'price': '2.50', 'quantity': 1},
          {'product_id': 2, 'name': 'Cola', 'price': '1.50', 'quantity': 2},
        ],
      });
      expect((combo.price, combo.regularPrice), (3.50, 4.00));
      expect(combo.endDate, DateTime(2026, 10, 31));
      expect(combo.items.map((i) => (i.productId, i.quantity)), [
        (1, 1),
        (2, 2),
      ]);
    });
  });
}
