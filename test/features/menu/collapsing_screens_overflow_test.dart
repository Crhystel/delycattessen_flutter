import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/menu_screen_test_support.dart';
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

final _items = [
  for (var i = 1; i <= 25; i++)
    product(
      i,
      'Producto con un nombre bastante largo número $i',
      1.0 + i / 10,
      category: i.isEven ? 'Bebidas' : 'Snacks',
    ),
];

final _offers = CatalogOffers(
  combos: [lunchCombo()],
  promotions: [colaPromotion()],
);

Widget _catalog(double scale) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: ProductCatalogView(
    title: 'Productos',
    showBackButton: true,
    headerAccessory: const Text('Menú del mes | Productos'),
    banner: const Text('Productos para Ana'),
    source: FakeCatalogSource(items: _items, offers: _offers),
  ),
);

void main() {
  // An overflow ("RenderFlex overflowed") is reported as a framework
  // exception, so a clean takeException means nothing was cut or overflowed.
  for (final entry in _sizes.entries) {
    for (final scale in _textScales) {
      final label = '${entry.key}, text x$scale';

      testWidgets('product catalog, expanded and folded: $label', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_catalog(scale));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('monthly menu, expanded and folded: $label', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          menuScreenApp(embedded: false, textScale: scale),
        );
        await settleMenu(tester);
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
