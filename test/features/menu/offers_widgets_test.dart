import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_offer_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/discount_offer_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/offers_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offers_test_support.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

final _catalog = {
  1: product(1, 'Sánduche', 2.50),
  2: product(2, 'Cola', 1.60, originalPrice: 2.00, discount: 20),
};

void main() {
  group('ComboOfferCard', () {
    testWidgets('shows its dishes, the price, the regular one and the saving', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ComboOfferCard(combo: lunchCombo(), itemsById: _catalog)),
      );

      expect(find.text('Combo almuerzo'), findsOneWidget);
      expect(find.text('Sánduche'), findsOneWidget);
      expect(find.text('Cola ×2'), findsOneWidget);
      expect(find.text('\$3.50'), findsOneWidget);
      expect(find.text('\$4.00'), findsOneWidget);
      expect(find.text('Ahorras \$0.50'), findsOneWidget);
      expect(find.text('Hasta el 31/12/2026'), findsOneWidget);
    });

    testWidgets('has no buy button in the consult-only catalogs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ComboOfferCard(combo: lunchCombo(), itemsById: _catalog)),
      );

      expect(find.text('Agregar combo'), findsNothing);
      expect(find.text('Cómpralo en caja'), findsOneWidget);
    });

    testWidgets('the POS button adds the whole combo', (tester) async {
      var added = 0;
      await tester.pumpWidget(
        _host(
          ComboOfferCard(
            combo: lunchCombo(),
            itemsById: _catalog,
            onAdd: () => added++,
          ),
        ),
      );

      await tester.tap(find.text('Agregar combo'));

      expect(added, 1);
      expect(find.text('Cómpralo en caja'), findsNothing);
    });

    testWidgets('shows how many are in the cart and the allergen badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ComboOfferCard(
            combo: lunchCombo(),
            itemsById: _catalog,
            onAdd: () {},
            inCart: 2,
            blocked: true,
          ),
        ),
      );

      expect(find.text('2 en carrito'), findsOneWidget);
      expect(find.text('Alérgeno'), findsOneWidget);
    });

    testWidgets('does not show a saving when the combo is not cheaper', (
      tester,
    ) async {
      final combo = Combo(
        id: 11,
        name: 'Combo igual',
        price: 4.00,
        regularPrice: 4.00,
        endDate: DateTime(2026, 12, 31),
        items: const [ComboItem(productId: 1, name: 'Sánduche', quantity: 1)],
      );
      await tester.pumpWidget(
        _host(ComboOfferCard(combo: combo, itemsById: _catalog)),
      );

      expect(find.textContaining('Ahorras'), findsNothing);
    });
  });

  group('DiscountOfferCard', () {
    testWidgets('shows the previous and the new price of each product', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DiscountOfferCard(promotion: colaPromotion(), itemsById: _catalog),
        ),
      );

      expect(find.text('-20%'), findsOneWidget);
      expect(find.text('Cola'), findsOneWidget);
      expect(find.text('\$2.00'), findsOneWidget); // previous, crossed out
      expect(find.text('\$1.60'), findsOneWidget); // new
      final previous = tester.widget<Text>(find.text('\$2.00'));
      expect(previous.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('falls back to the names when the catalog has no product', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DiscountOfferCard(promotion: colaPromotion(), itemsById: const {}),
        ),
      );

      expect(find.text('Cola'), findsOneWidget);
      expect(find.textContaining('\$'), findsNothing);
    });
  });

  group('OffersSection', () {
    testWidgets('shows the combos first and then the discounts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900); // one column
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          OffersSection(
            offers: CatalogOffers(
              combos: [lunchCombo()],
              promotions: [colaPromotion()],
            ),
            itemsById: _catalog,
          ),
        ),
      );

      expect(find.text('Ofertas de hoy'), findsOneWidget);
      expect(find.byType(ComboOfferCard), findsOneWidget);
      expect(find.byType(DiscountOfferCard), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(ComboOfferCard)).dy,
        lessThan(tester.getTopLeft(find.byType(DiscountOfferCard)).dy),
      );
    });

    testWidgets('takes no space without offers', (tester) async {
      await tester.pumpWidget(
        _host(OffersSection(offers: CatalogOffers.empty, itemsById: _catalog)),
      );

      expect(find.text('Ofertas de hoy'), findsNothing);
      expect(tester.getSize(find.byType(OffersSection)), Size.zero);
    });

    testWidgets('tapping a combo card opens its detail', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        _host(
          OffersSection(
            offers: CatalogOffers(combos: [lunchCombo()]),
            itemsById: _catalog,
            onComboTap: (combo) => tapped.add(combo.id),
          ),
        ),
      );

      await tester.tap(find.text('Combo almuerzo'));

      expect(tapped, [10]);
    });

    testWidgets('tapping a product of a discount opens that product', (
      tester,
    ) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        _host(
          OffersSection(
            offers: CatalogOffers(promotions: [colaPromotion()]),
            itemsById: _catalog,
            onProductTap: (item) => tapped.add(item.id),
          ),
        ),
      );

      await tester.tap(find.text('Cola'));

      expect(tapped, [2]);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('without callbacks the cards show no arrow', (tester) async {
      await tester.pumpWidget(
        _host(
          OffersSection(
            offers: CatalogOffers(
              combos: [lunchCombo()],
              promotions: [colaPromotion()],
            ),
            itemsById: _catalog,
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('the POS button works even when the card is tappable', (
      tester,
    ) async {
      final added = <int>[];
      final tapped = <int>[];
      await tester.pumpWidget(
        _host(
          OffersSection(
            offers: CatalogOffers(combos: [lunchCombo()]),
            itemsById: _catalog,
            onAddCombo: (combo) => added.add(combo.id),
            onComboTap: (combo) => tapped.add(combo.id),
          ),
        ),
      );

      await tester.tap(find.text('Agregar combo'));

      expect(added, [10]);
      expect(tapped, isEmpty); // the button does not open the detail
    });

    testWidgets('wires the POS callbacks to each combo', (tester) async {
      final added = <int>[];
      await tester.pumpWidget(
        _host(
          OffersSection(
            offers: CatalogOffers(combos: [lunchCombo()]),
            itemsById: _catalog,
            onAddCombo: (combo) => added.add(combo.id),
            comboQuantity: (_) => 3,
            isComboBlocked: (_) => false,
          ),
        ),
      );

      expect(find.text('3 en carrito'), findsOneWidget);
      await tester.tap(find.text('Agregar combo'));
      expect(added, [10]);
    });
  });
}
