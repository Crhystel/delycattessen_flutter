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
    test('uses the discounted price while a promotion is in force', () {
      final item = MenuItem.fromJson(product(finalPrice: '2.00', discount: 20));
      expect(item.price, 2.00);
      expect(item.discountPercentage, 20);
    });

    test('falls back to the original price without final_price', () {
      final item = MenuItem.fromJson(product());
      expect(item.price, 2.50);
      expect(item.discountPercentage, isNull);
    });
  });

  group('Promotion.fromJson', () {
    test('reads discount, end date, image and product names', () {
      final promotion = Promotion.fromJson({
        'id': 7,
        'discount_percentage': 15,
        'start_date': '2026-10-20',
        'end_date': '2026-10-31',
        'image': 'http://127.0.0.1:8000/media/promo.jpg',
        'products': [
          {'id': 1, 'name': 'Sandwich', 'price': '2.50', 'image': null},
          {'id': 2, 'name': 'Jugo', 'price': '1.00', 'image': null},
        ],
      });
      expect(promotion.discountPercentage, 15);
      expect(promotion.endDate, DateTime(2026, 10, 31));
      expect(promotion.imageUrl, 'http://127.0.0.1:8000/media/promo.jpg');
      expect(promotion.productNames, ['Sandwich', 'Jugo']);
    });

    test('accepts a promotion without image', () {
      final promotion = Promotion.fromJson({
        'id': 8,
        'discount_percentage': 10,
        'end_date': '2026-11-05',
        'image': null,
        'products': [],
      });
      expect(promotion.imageUrl, isNull);
      expect(promotion.productNames, isEmpty);
    });
  });
}
