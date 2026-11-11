import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_stock_badges.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_offer_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/offers_section.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

final _items = [
  product(1, 'Sánduche', 2.50),
  product(2, 'Cola', 1.60),
  for (var i = 3; i <= 8; i++) product(i, 'Producto $i', 1.0 + i / 10),
];

Combo _combo(int id, String name, {int? available}) => Combo(
  id: id,
  name: name,
  price: 3.50,
  regularPrice: 4.00,
  endDate: DateTime(2026, 12, 31),
  availableQuantity: available,
  items: const [ComboItem(productId: 1, name: 'Sánduche', quantity: 1)],
);

final _byId = {for (final item in _items) item.id: item};

Future<void> _pumpCatalog(
  WidgetTester tester,
  CatalogOffers offers, {
  bool flat = false,
}) async {
  tester.view.physicalSize = const Size(411, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ProductCatalogView(
        source: FakeCatalogSource(items: _items, offers: offers),
        flatLayout: flat,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpPosOffers(WidgetTester tester, List<Combo> combos) async {
  tester.view.physicalSize = const Size(411, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OffersSection(
            offers: CatalogOffers(combos: combos),
            itemsById: _byId,
            onAddCombo: (_) {},
            stockBadge: CatalogStockBadges.exact,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _opacityOf(WidgetTester tester, String comboName) => tester
    .widget<Opacity>(
      find
          .descendant(
            of: find.ancestor(
              of: find.text(comboName),
              matching: find.byType(ComboOfferCard),
            ),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  group('informational catalogs (parents, students, teachers)', () {
    testWidgets('a sold out combo does not appear in the offers', (
      tester,
    ) async {
      await _pumpCatalog(
        tester,
        CatalogOffers(
          combos: [
            _combo(1, 'Combo agotado', available: 0),
            _combo(2, 'Combo disponible', available: 12),
          ],
        ),
      );

      expect(find.text('Combo agotado'), findsNothing);
      expect(find.text('Combo disponible'), findsOneWidget);
    });

    testWidgets('with only sold out combos there is no offers section', (
      tester,
    ) async {
      await _pumpCatalog(
        tester,
        CatalogOffers(combos: [_combo(1, 'Combo agotado', available: 0)]),
      );

      expect(find.byType(OffersSection), findsNothing);
      expect(find.text('Combo agotado'), findsNothing);
    });

    testWidgets('the parent carousel hides it too and warns of low stock', (
      tester,
    ) async {
      await _pumpCatalog(
        tester,
        CatalogOffers(
          combos: [
            _combo(1, 'Combo agotado', available: 0),
            _combo(2, 'Combo escaso', available: 3),
          ],
        ),
        flat: true,
      );

      expect(find.text('Combo agotado'), findsNothing);
      expect(find.text('Combo escaso'), findsOneWidget);
      expect(find.text('Quedan 3'), findsOneWidget);
    });

    testWidgets('the card says "Quedan N" and "Última unidad"', (tester) async {
      await _pumpCatalog(
        tester,
        CatalogOffers(
          combos: [
            _combo(1, 'Combo escaso', available: 4),
            _combo(2, 'Combo último', available: 1),
            _combo(3, 'Combo holgado', available: 50),
            _combo(4, 'Combo sin dato'),
          ],
        ),
      );

      expect(find.text('Quedan 4'), findsOneWidget);
      expect(find.text('Última unidad'), findsOneWidget);
      expect(find.text('Combo holgado'), findsOneWidget);
      expect(find.text('Combo sin dato'), findsOneWidget);
      expect(find.textContaining('Stock:'), findsNothing);
      expect(find.text('Agotado'), findsNothing);
    });
  });

  group('POS offers', () {
    testWidgets('shows every combo with its exact stock', (tester) async {
      await _pumpPosOffers(tester, [_combo(1, 'Combo A', available: 7)]);

      expect(find.text('Stock: 7'), findsOneWidget);
      expect(find.text('Agregar combo'), findsOneWidget);
      expect(_opacityOf(tester, 'Combo A'), 1.0);
    });

    testWidgets(
      'a sold out combo is dimmed, says Agotado and cannot be added',
      (tester) async {
        await _pumpPosOffers(tester, [
          _combo(1, 'Combo agotado', available: 0),
          _combo(2, 'Combo disponible', available: 2),
        ]);

        expect(find.text('Combo agotado'), findsOneWidget);
        expect(find.text('Agotado'), findsOneWidget);
        expect(find.text('Stock: 0'), findsNothing);
        // Only the available one has the add button.
        expect(find.text('Agregar combo'), findsOneWidget);
        expect(_opacityOf(tester, 'Combo agotado'), lessThan(1.0));
        expect(_opacityOf(tester, 'Combo disponible'), 1.0);
      },
    );
  });

  group('overflow', () {
    const sizes = <String, Size>{
      'small phone 320x568': Size(320, 568),
      'phone 360x640': Size(360, 640),
      'large phone 411x891': Size(411, 891),
      'tablet 800x1280': Size(800, 1280),
    };
    final combos = [
      _combo(
        1,
        'Combo almuerzo familiar con bebida y postre incluidos hoy',
        available: 0,
      ),
      _combo(
        2,
        'Combo desayuno con jugo natural y galleta artesanal',
        available: 1,
      ),
      _combo(3, 'Combo merienda con cola y sánduche', available: 4),
    ];

    Widget host(double scale, Widget child) => MaterialApp(
      builder: (context, content) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: content!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    for (final entry in sizes.entries) {
      for (final scale in [1.0, 2.0]) {
        for (final badge in <String, StockBadgeBuilder>{
          'Quedan N': CatalogStockBadges.low,
          'Stock: N': CatalogStockBadges.exact,
        }.entries) {
          testWidgets('offers with ${badge.key}: ${entry.key}, text x$scale', (
            tester,
          ) async {
            tester.view.physicalSize = entry.value;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              host(
                scale,
                OffersSection(
                  offers: CatalogOffers(combos: combos),
                  itemsById: _byId,
                  onAddCombo: (_) {},
                  stockBadge: badge.value,
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 100));

            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('parent carousel with the stock pill: text x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            scale,
            OffersSection(
              offers: CatalogOffers(combos: combos.sublist(1)),
              itemsById: _byId,
              carousel: true,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Última unidad'), findsOneWidget);
      });
    }
  });
}
