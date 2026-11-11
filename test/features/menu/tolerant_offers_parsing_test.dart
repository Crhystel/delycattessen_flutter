import 'package:delycattessen_flutter/core/network/api_config.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers the combos endpoint with fixed JSON and records the URLs asked.
class _OffersService extends MenuService {
  _OffersService({required this.combos});

  final List<Object?> combos;
  final requestedUrls = <String>[];

  @override
  Future<dynamic> performGetRequest(
    String url, {
    bool requiresAuth = true,
  }) async {
    requestedUrls.add(url);
    return combos;
  }
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

  group('MenuService.getActiveOffers', () {
    test('an offer without id is skipped and the others are kept', () async {
      final service = _OffersService(
        combos: [
          {'name': 'sin id', 'price': '1.00'},
          {'id': 3, 'name': 'Promo', 'price': '2.00', 'end_date': null},
          'basura',
        ],
      );

      final offers = await service.getActiveOffers(studentId: 5);

      expect(offers.combos.map((c) => c.id), [3]);
    });

    test('asks only for the combos endpoint', () async {
      final service = _OffersService(combos: const []);

      await service.getActiveOffers(studentId: 5);

      expect(service.requestedUrls, hasLength(1));
      expect(service.requestedUrls.single, startsWith(ApiConfig.activeCombos));
    });

    test('combos with and without the stock fields live together', () async {
      final service = _OffersService(
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
