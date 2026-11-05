import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/widgets/offers_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

/// Phones from small to large, landscape and a tablet (logical dp).
const _sizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 360x640': Size(360, 640),
  'large phone 411x891': Size(411, 891),
  'landscape phone 740x360': Size(740, 360),
  'tablet 800x1280': Size(800, 1280),
};

const _textScales = [1.0, 2.0];

const _long = 'Sánduche de pollo con queso derretido y vegetales frescos';

final _catalog = {
  1: product(1, _long, 2.50, originalPrice: 3.00, discount: 17),
  2: product(2, 'Cola personal de vidrio retornable', 1.60),
  3: product(3, 'Galleta artesanal de avena con pasas', 1.00),
};

final _offers = CatalogOffers(
  combos: [
    lunchCombo(
      name: 'Combo almuerzo familiar con bebida y postre incluidos hoy',
      items: const [
        ComboItem(productId: 1, name: _long, quantity: 2),
        ComboItem(
          productId: 2,
          name: 'Cola personal de vidrio retornable',
          quantity: 2,
        ),
        ComboItem(
          productId: 3,
          name: 'Galleta artesanal de avena con pasas',
          quantity: 1,
        ),
      ],
    ),
  ],
  promotions: [
    Promotion(
      id: 1,
      discountPercentage: 17,
      endDate: DateTime(2026, 12, 31),
      productNames: const [_long, 'Galleta artesanal de avena con pasas'],
      productIds: const [1, 3],
    ),
  ],
);

void main() {
  // An overflow ("RenderFlex overflowed") is reported as a framework
  // exception, so a clean takeException means nothing was cut or overflowed.
  for (final entry in _sizes.entries) {
    for (final scale in _textScales) {
      testWidgets('offers with long names: ${entry.key}, text x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: OffersSection(
                  offers: _offers,
                  itemsById: _catalog,
                  onAddCombo: (_) {},
                  comboQuantity: (_) => 12,
                  isComboBlocked: (_) => true,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Agregar combo'), findsOneWidget);
      });

      testWidgets(
        'product detail with a long name: ${entry.key}, text x$scale',
        (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: ProductDetailScreen(item: _catalog[1]!, onAdd: (_) {}),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('combo detail with long names: ${entry.key}, text x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: ComboDetailScreen(
              combo: _offers.combos.first,
              itemsById: _catalog,
              onAdd: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Añadir'), findsOneWidget);
      });
    }
  }
}
