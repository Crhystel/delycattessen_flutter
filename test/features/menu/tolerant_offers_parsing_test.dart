import 'package:delycattessen_flutter/core/network/api_config.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers the two offers endpoints with fixed JSON.
class _OffersService extends MenuService {
  _OffersService({required this.promotions, required this.combos});

  final List<Object?> promotions;
  final List<Object?> combos;

  @override
  Future<dynamic> performGetRequest(
    String url, {
    bool requiresAuth = true,
  }) async => url.startsWith(ApiConfig.activePromotions) ? promotions : combos;
}

void main() {
  group('Combo.fromJson', () {
    test('null name, price, date and image take defaults', () {
      final combo = Combo.fromJson({
        'id': 4,
        'name': null,
        'price': null,
        'regular_price': null,
        'end_date': null,
        'image': null,
      });

      expect(combo.id, 4);
      expect(combo.name, '');
      expect(combo.price, 0.0);
      expect(combo.regularPrice, 0.0);
      expect(combo.imageUrl, isNull);
      expect(combo.items, isEmpty);
    });

    test('items with null fields do not break the combo', () {
      final combo = Combo.fromJson({
        'id': 4,
        'name': 'Promo',
        'price': '2.00',
        'end_date': '2026-11-12',
        'items': [
          {'product_id': null, 'name': null, 'quantity': null},
        ],
      });

      expect(combo.items.single.name, '');
      expect(combo.items.single.quantity, 1);
      expect(combo.endDate, DateTime(2026, 11, 12));
    });
  });

  group('Promotion.fromJson', () {
    test('null discount, date and product names take defaults', () {
      final promotion = Promotion.fromJson({
        'id': 9,
        'discount_percentage': null,
        'end_date': 'no es una fecha',
        'products': [
          {'id': 7, 'name': null},
        ],
      });

      expect(promotion.discountPercentage, 0);
      expect(promotion.productNames, ['']);
      expect(promotion.productIds, [7]);
    });
  });

  group('MenuService.getActiveOffers', () {
    test('an offer without id is skipped and the others are kept', () async {
      final service = _OffersService(
        promotions: [
          {'id': null, 'discount_percentage': 10, 'end_date': '2026-12-31'},
          {'id': 2, 'discount_percentage': 15, 'end_date': '2026-12-31'},
        ],
        combos: [
          {'name': 'sin id', 'price': '1.00'},
          {'id': 3, 'name': 'Promo', 'price': '2.00', 'end_date': null},
          'basura',
        ],
      );

      final offers = await service.getActiveOffers(studentId: 5);

      expect(offers.promotions.map((p) => p.id), [2]);
      expect(offers.combos.map((c) => c.id), [3]);
    });

    test('combos with and without the stock fields live together', () async {
      final service = _OffersService(
        promotions: const [],
        combos: [
          {
            'id': 1,
            'name': 'Con stock',
            'available_quantity': 0,
            'is_available': false,
            'items': [
              {'product_id': 1, 'name': 'A', 'quantity': 1, 'stock': 0},
            ],
          },
          {
            'id': 2,
            'name': 'Sin campos nuevos',
            'items': [
              {'product_id': 1, 'name': 'A', 'quantity': 1},
            ],
          },
        ],
      );

      final offers = await service.getActiveOffers();

      expect(offers.combos.map((c) => c.availableQuantity), [0, null]);
      expect(offers.visibleCombos.map((c) => c.id), [2]);
    });
  });
}
