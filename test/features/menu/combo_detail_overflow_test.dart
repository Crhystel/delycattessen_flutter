import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_stock_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/detail_test_support.dart';

Combo _combo(int id, String name, {int? available}) => Combo(
  id: id,
  name: name,
  price: 2.00,
  regularPrice: 7.00,
  endDate: DateTime(2026, 12, 31),
  availableQuantity: available,
  items: const [
    ComboItem(
      productId: 1,
      name: 'Crepes con frutas de temporada y salsa de chocolate',
      quantity: 1,
    ),
    ComboItem(productId: 2, name: 'Tostada', quantity: 2),
    ComboItem(productId: 3, name: 'Producto fuera del catálogo', quantity: 1),
  ],
);

MenuItem _item(int id, String name) => MenuItem(
  id: id,
  name: name,
  description: '',
  price: 5.0,
  category: 'Snacks',
  ingredients: const [],
  allergens: const [],
  stock: 10,
);

void main() {
  final combos = [
    _combo(1, 'Combo familiar con bebida, postre y papas fritas incluidos'),
    _combo(2, 'Promo barata'),
    _combo(3, 'Combo desayuno con jugo natural y galleta artesanal'),
  ];
  final conflict = AllergenAdvisory.of(
    allergens: [
      'Gluten',
      'Lácteos',
      'Frutos secos con cáscara',
      'Sulfitos',
      'Huevo',
    ],
    conflicts: ['Gluten', 'Frutos secos con cáscara'],
    audience: const AllergenAudience.named(
      'María de los Ángeles Fernández de la Vega',
    ),
  );

  for (final size in detailSizes.entries) {
    for (final scale in detailTextScales) {
      for (final canAdd in [true, false]) {
        testWidgets('combo in conflict ${canAdd ? 'with' : 'without'} bar: '
            '${size.key}, text x$scale', (tester) async {
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, page) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: page!,
              ),
              home: ComboDetailScreen(
                combo: combos.first,
                itemsById: {1: _item(1, 'Crepes'), 2: _item(2, 'Tostada')},
                onAdd: canAdd ? (_) {} : null,
                stockBadge: CatalogStockBadges.exact,
                advisory: conflict,
                otherCombos: combos.sublist(1),
                onComboTap: (_) {},
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
