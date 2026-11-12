import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/dish_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/detail_test_support.dart';

final _dish = MenuDish(
  id: 1,
  name: 'Pollo asado con arroz, ensalada fresca y jugo natural de la casa',
  description:
      'Pechuga de pollo al horno con arroz blanco, ensalada y jugo de temporada',
  price: 12.5,
  allergens: const ['Gluten', 'Lácteos', 'Sulfitos', 'Frutos secos'],
);

final _conflict = AllergenAdvisory.of(
  allergens: _dish.allergens,
  conflicts: const ['Gluten', 'Lácteos', 'Frutos secos'],
  audience: const AllergenAudience.named('Pepito Alejandro'),
);

void main() {
  // An overflow ("RenderFlex overflowed") is a framework exception, so a clean
  // takeException means nothing was cut or overflowed.
  for (final entry in detailSizes.entries) {
    for (final scale in detailTextScales) {
      testWidgets('dish detail with a conflict: ${entry.key}, text x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: page!,
            ),
            home: DishDetailScreen(
              dish: _dish,
              onAdd: (_) {},
              servedDate: DateTime(2026, 11, 10),
              advisory: _conflict,
              orderingFor: 'Pepito Alejandro Pérez Villavicencio',
              onChangeChild: () async => false,
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
