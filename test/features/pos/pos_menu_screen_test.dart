import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/combo_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/product_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_item_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_offer_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:delycattessen_flutter/features/pos/models/pos_identification_model.dart';
import 'package:delycattessen_flutter/features/pos/screens/pos_menu_screen.dart';
import 'package:delycattessen_flutter/features/pos/widgets/pos_cart_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MenuItem _item(int id, String name, List<String> allergens) => MenuItem(
  id: id,
  name: name,
  description: '',
  price: 2.0,
  category: 'Snacks',
  ingredients: const [],
  allergens: [
    for (var i = 0; i < allergens.length; i++)
      Allergen(id: id * 10 + i, name: allergens[i]),
  ],
  stock: 10,
);

Combo _combo(int id, String name, List<ComboItem> items) => Combo(
  id: id,
  name: name,
  price: 3.5,
  regularPrice: 4.0,
  endDate: DateTime(2026, 12, 31),
  availableQuantity: 5,
  items: items,
);

class _FakeMenuService extends MenuService {
  @override
  Future<List<MenuItem>> getMenu({int? studentId}) async => [
    _item(1, 'Sánduche', ['Gluten']),
    _item(2, 'Jugo', const []),
  ];

  @override
  Future<CatalogOffers> getActiveOffers({int? studentId}) async =>
      CatalogOffers(
        combos: [
          _combo(10, 'Combo almuerzo', const [
            ComboItem(productId: 1, name: 'Sánduche', quantity: 1),
            ComboItem(productId: 2, name: 'Jugo', quantity: 1),
          ]),
          _combo(11, 'Combo fresco', const [
            ComboItem(productId: 2, name: 'Jugo', quantity: 2),
          ]),
        ],
      );
}

IdentifiedUser _customer({List<String> allergies = const ['Gluten']}) =>
    IdentifiedUser(
      userId: 1,
      username: 'pepito',
      fullName: 'Pepito Pérez',
      role: 'STUDENT',
      roleDisplay: 'Estudiante',
      balance: 10,
      allergies: allergies,
      pendingOrders: const [],
      identificationMethod: 'QR',
    );

Future<void> _pump(WidgetTester tester, IdentifiedUser? user) async {
  tester.view.physicalSize = const Size(411, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: PosMenuScreen(user: user, menuService: _FakeMenuService()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the card of a product or a combo (their names also appear inside the
/// combo cards) and waits for the detail screen.
Future<void> _tapCard(WidgetTester tester, String name) async {
  final card = find.descendant(
    of: find.byType(
      name.startsWith('Combo') ? ComboOfferCard : CatalogItemCard,
    ),
    matching: find.text(name),
  );
  await tester.tap(card.first);
  await tester.pumpAndSettle();
}

void main() {
  group('customer with an allergy', () {
    testWidgets('a product with the allergen opens its detail, blocked', (
      tester,
    ) async {
      await _pump(tester, _customer());

      await _tapCard(tester, 'Sánduche');

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Producto no disponible'), findsNothing);
      expect(find.text('Contiene gluten'), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsOneWidget);
      expect(find.text('No disponible para Pepito Pérez'), findsOneWidget);
      expect(find.byType(QuantityAddBar), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('a combo with the allergen opens its detail, blocked', (
      tester,
    ) async {
      await _pump(tester, _customer());

      await _tapCard(tester, 'Combo almuerzo');

      expect(find.byType(ComboDetailScreen), findsOneWidget);
      expect(find.text('Combo no disponible'), findsNothing);
      expect(find.text('Contiene gluten'), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsOneWidget);
      expect(find.byType(QuantityAddBar), findsNothing);
      expect(find.text('Otros combos'), findsOneWidget);
    });

    testWidgets('the cards keep the red badge', (tester) async {
      await _pump(tester, _customer());

      expect(
        find.text('Alérgeno'),
        findsNWidgets(2),
      ); // the product and a combo
    });

    testWidgets('a safe product can be added from its detail', (tester) async {
      await _pump(tester, _customer());

      await _tapCard(tester, 'Jugo');
      expect(find.byType(BlockedPurchaseBar), findsNothing);
      await tester.tap(find.textContaining('Añadir'));
      await tester.pumpAndSettle();

      expect(find.byType(PosCartBar), findsOneWidget);
    });

    testWidgets('a product with the allergen never reaches the cart', (
      tester,
    ) async {
      await _pump(tester, _customer());
      await _tapCard(tester, 'Sánduche');

      // Even if something called the detail's add callback, the screen
      // refuses and explains why.
      tester
          .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
          .onAdd!(1);
      await tester.pumpAndSettle();

      expect(find.text('Producto no disponible'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10)); // notice times out
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byType(PosCartBar), findsNothing);
    });

    testWidgets('a combo with the allergen never reaches the cart', (
      tester,
    ) async {
      await _pump(tester, _customer());
      await _tapCard(tester, 'Combo almuerzo');

      tester.widget<ComboDetailScreen>(find.byType(ComboDetailScreen)).onAdd!(
        1,
      );
      await tester.pumpAndSettle();

      expect(find.text('Combo no disponible'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10)); // notice times out
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byType(PosCartBar), findsNothing);
    });

    testWidgets('the product lists the combos that include it', (tester) async {
      await _pump(tester, _customer());

      await _tapCard(tester, 'Jugo');

      final detail = tester.widget<ProductDetailScreen>(
        find.byType(ProductDetailScreen),
      );
      expect(detail.combos.map((c) => c.name), [
        'Combo almuerzo',
        'Combo fresco',
      ]);
      expect(detail.exactStock, isTrue);
    });
  });

  group('without an identified customer', () {
    testWidgets('the detail shows the allergens but no verdict', (
      tester,
    ) async {
      await _pump(tester, null);

      await _tapCard(tester, 'Sánduche');

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Gluten'), findsOneWidget);
      expect(find.textContaining('registrada'), findsNothing);
      expect(find.byType(BlockedPurchaseBar), findsNothing);
      expect(find.byType(QuantityAddBar), findsOneWidget);
    });
  });
}
