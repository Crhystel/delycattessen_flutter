import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_item_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

final _peanuts = Allergen(id: 3, name: 'Maní');

final _items = [
  MenuItem(
    id: 1,
    name: 'Barra de maní',
    description: 'Snack',
    price: 1.5,
    category: 'Snacks',
    ingredients: const [],
    allergens: [_peanuts],
    stock: 10,
  ),
  product(2, 'Cola', 1.6, category: 'Bebidas'),
];

Future<void> _pump(
  WidgetTester tester, {
  required AllergenAudience audience,
  CatalogOffers offers = CatalogOffers.empty,
  Set<int> allergenIds = const {3},
}) async {
  tester.view.physicalSize = const Size(411, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ProductCatalogView(
        source: FakeCatalogSource(
          items: _items,
          offers: offers,
          allergenIds: allergenIds,
          allergenAudience: audience,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _openPeanutBar(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(CatalogItemCard, 'Barra de maní'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a product with an allergen of the child opens its detail', (
    tester,
  ) async {
    await _pump(tester, audience: const AllergenAudience.named('Pepito'));

    await _openPeanutBar(tester);

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Producto no disponible'), findsNothing);
    expect(find.text('Contiene maní'), findsOneWidget);
    expect(
      find.text(
        'Pepito tiene registrada esta alergia, por eso este producto no se le '
        'puede vender.',
      ),
      findsOneWidget,
    );
    // Consult-only catalogs have no purchase bar, blocked or not.
    expect(find.byType(BlockedPurchaseBar), findsNothing);
  });

  testWidgets('a student or teacher sees "Tienes registrada"', (tester) async {
    await _pump(tester, audience: AllergenAudience.self);

    await _openPeanutBar(tester);

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(
      find.text(
        'Tienes registrada esta alergia, por eso este producto no se te puede '
        'vender.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the card keeps the allergen badge and is dimmed', (
    tester,
  ) async {
    await _pump(tester, audience: AllergenAudience.self);

    final card = tester.widget<CatalogItemCard>(
      find.widgetWithText(CatalogItemCard, 'Barra de maní'),
    );
    expect(card.dimmed, isTrue);
    expect(card.badges, isNotEmpty);
  });

  testWidgets('a product without conflict shows the green box', (tester) async {
    await _pump(
      tester,
      audience: const AllergenAudience.named('Pepito'),
      allergenIds: const {},
    );

    await _openPeanutBar(tester);

    expect(
      find.text('Pepito no tiene registrada esta alergia.'),
      findsOneWidget,
    );
  });

  testWidgets('the product detail lists the combos that include it', (
    tester,
  ) async {
    await _pump(
      tester,
      audience: AllergenAudience.self,
      offers: CatalogOffers(
        combos: [
          lunchCombo(
            items: const [
              ComboItem(productId: 1, name: 'Barra de maní', quantity: 1),
            ],
          ),
        ],
      ),
    );

    await _openPeanutBar(tester);

    expect(find.text('También en combo'), findsOneWidget);
    await tester.ensureVisible(find.text('Combo almuerzo'));
    await tester.tap(find.text('Combo almuerzo'));
    await tester.pumpAndSettle();

    expect(find.byType(ComboDetailScreen), findsOneWidget);
  });

  testWidgets('a combo with an allergen of the user opens with the warning', (
    tester,
  ) async {
    await _pump(
      tester,
      audience: const AllergenAudience.named('Pepito'),
      offers: CatalogOffers(
        combos: [
          lunchCombo(
            items: const [
              ComboItem(productId: 1, name: 'Barra de maní', quantity: 1),
              ComboItem(productId: 2, name: 'Cola', quantity: 1),
            ],
          ),
        ],
      ),
    );

    await tester.tap(find.text('Combo almuerzo').hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(ComboDetailScreen), findsOneWidget);
    expect(find.text('Contiene maní'), findsOneWidget);
  });
}
