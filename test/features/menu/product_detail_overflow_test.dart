import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/detail_test_support.dart';

final _item = MenuItem(
  id: 1,
  name: 'Sánduche de pollo con queso derretido y salsa de la casa',
  description:
      'Pan artesanal con pollo a la plancha, queso, lechuga, tomate y una '
      'salsa especial preparada cada mañana',
  price: 1234.56,
  category: 'Almuerzos y platos fuertes del día',
  ingredients: [
    for (final name in ['Pan', 'Pollo', 'Queso mozzarella', 'Lechuga crespa'])
      Ingredient(id: name.length, name: name),
  ],
  allergens: [
    Allergen(id: 1, name: 'Gluten'),
    Allergen(id: 2, name: 'Lácteos'),
  ],
  stock: 3,
);

final _combos = [
  for (var i = 1; i <= 2; i++)
    Combo(
      id: i,
      name: 'Combo almuerzo familiar con bebida y postre incluidos $i',
      price: 12.5,
      regularPrice: 20,
      endDate: DateTime(2026, 12, 31),
      items: const [
        ComboItem(
          productId: 1,
          name: 'Sánduche de pollo con queso',
          quantity: 2,
        ),
        ComboItem(productId: 2, name: 'Cola personal de vidrio', quantity: 1),
      ],
    ),
];

final _conflict = AllergenAdvisory.of(
  allergens: ['Gluten', 'Lácteos', 'Frutos secos', 'Mariscos'],
  conflicts: ['Gluten', 'Lácteos', 'Frutos secos'],
  audience: const AllergenAudience.named(
    'Pepito Alejandro Pérez Villavicencio',
  ),
);

void main() {
  // An overflow is a framework exception, so a clean takeException means
  // nothing was cut off.
  for (final entry in detailSizes.entries) {
    for (final scale in detailTextScales) {
      testWidgets('product detail in conflict: ${entry.key}, text x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
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
            home: ProductDetailScreen(
              item: _item,
              onAdd: (_) {},
              advisory: _conflict,
              combos: _combos,
              onComboTap: (_) {},
              exactStock: true,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(
          find.text('No disponible para Pepito Alejandro Pérez Villavicencio'),
          findsOneWidget,
        );
      });
    }
  }
}
