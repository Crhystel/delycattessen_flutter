import 'package:delycattessen_flutter/core/theme/app_colors.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/order_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_item_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/catalog_search_row.dart';
import 'package:delycattessen_flutter/features/menu/widgets/category_filter_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/combo_carousel.dart';
import 'package:delycattessen_flutter/features/menu/widgets/order_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 390x844': Size(390, 844),
  'tablet 768x1024': Size(768, 1024),
};

Combo _combo(int id, String name, {double price = 2, double regular = 7}) =>
    Combo(
      id: id,
      name: name,
      price: price,
      regularPrice: regular,
      endDate: DateTime(2026, 11, 12),
      items: const [
        ComboItem(productId: 1, name: 'Crepes', quantity: 1),
        ComboItem(productId: 2, name: 'Tostada', quantity: 2),
      ],
    );

PreOrderItemDetail _item(
  String name, {
  int quantity = 1,
  String? image,
  double price = 3.5,
}) => PreOrderItemDetail(
  id: 1,
  dishId: 1,
  dishName: name,
  quantity: quantity,
  priceAtPurchase: price,
  imageUrl: image,
);

OrderEntry _order({
  List<PreOrderItemDetail>? items,
  OrderOrigin origin = OrderOrigin.pointOfSale,
  PreOrderStatus status = PreOrderStatus.delivered,
  String deliveryDate = '',
}) => OrderEntry(
  id: 7,
  studentId: 3,
  studentName: 'Julieta Venegas',
  createdAt: DateTime(2026, 10, 15, 22, 49),
  status: status,
  statusDisplay: status == PreOrderStatus.pending ? 'Pendiente' : 'Entregado',
  deliveryDate: deliveryDate,
  totalAmount: 3.5,
  items: items ?? [_item('Pollo asado')],
  origin: origin,
  paymentLabel: 'Billetera',
);

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double textScale,
  Widget body,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: body)),
    ),
  );
}

/// Replaces the tree so the carousel's periodic timer is cancelled.
Future<void> _unmount(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

void main() {
  group('ComboCarousel', () {
    final combos = [
      _combo(1, 'Promo barata'),
      _combo(2, 'Dulce tarde'),
      _combo(3, 'Recreo frío'),
    ];

    testWidgets('shows the counter and a dot per combo, and advances alone', (
      tester,
    ) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        ComboCarousel(combos: combos, autoAdvance: const Duration(seconds: 1)),
      );

      expect(find.text('Combos de hoy'), findsOneWidget);
      expect(find.text('1 de 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Ver combo 3 de 3'), findsOneWidget);
      expect(find.text('Ahorras \$5.00'), findsWidgets);
      expect(find.text('Crepes + Tostada ×2'), findsWidgets);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('2 de 3'), findsOneWidget);

      await _unmount(tester);
    });

    testWidgets('a dot jumps to that combo and a tap opens it', (tester) async {
      Combo? opened;
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        ComboCarousel(combos: combos, onComboTap: (c) => opened = c),
      );

      await tester.tap(find.bySemanticsLabel('Ver combo 3 de 3'));
      await tester.pump(); // the scroll animation starts on this frame
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('3 de 3'), findsOneWidget);

      await tester.tap(find.text('Recreo frío'));
      expect(opened?.id, 3);

      await _unmount(tester);
    });

    testWidgets('a single combo has no counter and no dots', (tester) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        ComboCarousel(combos: [combos.first]),
      );

      expect(find.text('Combos de hoy'), findsOneWidget);
      expect(find.textContaining(' de 1'), findsNothing);
      expect(find.bySemanticsLabel('Ver combo 1 de 1'), findsNothing);

      await _unmount(tester);
    });

    for (final entry in _sizes.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('fits: ${entry.key}, text x$scale', (tester) async {
          await _pump(
            tester,
            entry.value,
            scale,
            ComboCarousel(combos: combos),
          );

          expect(tester.takeException(), isNull);
          await _unmount(tester);
        });
      }
    }
  });

  group('OrderRow', () {
    testWidgets('shows a placeholder when the product has no photo', (
      tester,
    ) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        OrderRow(order: _order(), onTap: () {}),
      );

      expect(find.byIcon(Icons.fastfood), findsOneWidget);
      expect(find.text('1× Pollo asado'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
    });

    testWidgets('a delivered row inside a day card has no photo', (
      tester,
    ) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        OrderRow(order: _order(), grouped: true, onTap: () {}),
      );

      expect(find.byType(OrderPhoto), findsNothing);
      expect(find.text('Entregado'), findsOneWidget);
    });

    testWidgets('the pending chip uses the amber brand colors', (tester) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        const OrderStatusChip(
          status: PreOrderStatus.pending,
          label: 'Pendiente',
        ),
      );

      final text = tester.widget<Text>(find.text('Pendiente'));
      expect(text.style?.color, AppColors.brand700);
      final box = tester.widget<Container>(find.byType(Container).first);
      expect((box.decoration as BoxDecoration).color, AppColors.brand50);
    });

    testWidgets('lists "+N más" and the pre-order date', (tester) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        OrderRow(
          order: _order(
            items: [_item('Crepes', quantity: 2), _item('Helado')],
            origin: OrderOrigin.preorder,
            status: PreOrderStatus.pending,
            deliveryDate: '2026-11-10',
          ),
          onTap: () {},
        ),
      );

      expect(find.text('2× Crepes +1 más'), findsOneWidget);
      expect(find.textContaining('Preorden'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('a tap reports it, grouped or not', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        Column(
          children: [
            OrderRow(order: _order(), onTap: () => taps++),
            OrderRow(order: _order(), grouped: true, onTap: () => taps++),
          ],
        ),
      );

      await tester.tap(find.byType(OrderRow).first);
      await tester.tap(find.byType(OrderRow).last);
      expect(taps, 2);
    });

    for (final entry in _sizes.entries) {
      testWidgets('fits: ${entry.key}, text x2', (tester) async {
        await _pump(
          tester,
          entry.value,
          2,
          Column(
            children: [
              OrderRow(
                order: _order(
                  items: [
                    _item('Pollo asado con arroz, maduro y ensalada fresca'),
                    _item('Helado'),
                  ],
                ),
                onTap: () {},
              ),
              OrderRow(order: _order(), grouped: true, onTap: () {}),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('order models', () {
    test('a purchase keeps the child and the product photo', () {
      final order = OrderEntry.fromPurchaseJson({
        'id': 9,
        'student_id': 4,
        'student_name': 'Ana',
        'total_amount': '1.00',
        'created_at': '2026-10-22T21:55:00Z',
        'items': [
          {
            'menu_item_name': 'Helado',
            'quantity': 1,
            'price_at_purchase': '1.00',
            'image': 'https://x.test/helado.jpg',
          },
          {
            'menu_item_name': 'Pan',
            'quantity': 1,
            'price_at_purchase': '0.50',
            'image': null,
          },
        ],
      });

      expect(order.studentId, 4);
      expect(order.items.first.imageUrl, 'https://x.test/helado.jpg');
      expect(order.items.last.imageUrl, isNull);
    });

    test('an item from an old backend has no photo', () {
      final item = PreOrderItemDetail.fromJson({
        'id': 1,
        'dish': 2,
        'dish_name': 'Pollo',
        'quantity': 1,
        'price_at_purchase': '3.50',
      });

      expect(item.imageUrl, isNull);
    });
  });

  group('OrderDetailScreen', () {
    Widget screen({int? walletId}) => MaterialApp(
      home: OrderDetailScreen(order: _order(), walletId: walletId),
    );

    testWidgets('shows the receipt: status, total, data and breakdown', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(screen());

      expect(find.text('Detalle del pedido'), findsOneWidget);
      expect(find.text('Pedido N.º 7'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
      expect(find.text('Julieta Venegas'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      // The table has quantity, product and price only (no "Importe" column),
      // and without a discount there is no "Descuento" line.
      expect(find.text('Precio'), findsOneWidget);
      expect(find.text('Importe'), findsNothing);
      expect(find.text('Descuento'), findsNothing);
      expect(find.text('Ver en movimientos de la billetera'), findsNothing);
    });

    testWidgets('shows the discount line only when there was a discount', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Items add up to 5.00 but the order total is 3.50: a 1.50 discount.
      final discounted = OrderEntry(
        id: 8,
        studentId: 3,
        studentName: 'Julieta Venegas',
        createdAt: DateTime(2026, 10, 15, 22, 49),
        status: PreOrderStatus.delivered,
        statusDisplay: 'Entregado',
        deliveryDate: '',
        totalAmount: 3.5,
        items: [_item('Crepes', price: 5.0)],
        origin: OrderOrigin.pointOfSale,
        paymentLabel: 'Billetera',
      );
      await tester.pumpWidget(
        MaterialApp(home: OrderDetailScreen(order: discounted)),
      );

      expect(find.text('Descuento'), findsOneWidget);
      expect(find.text('\$1.50'), findsOneWidget);
    });

    testWidgets('offers the wallet movements only when the wallet is known', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(screen(walletId: 5));

      expect(find.text('Ver en movimientos de la billetera'), findsOneWidget);
    });

    for (final entry in _sizes.entries) {
      testWidgets('fits: ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(screen(walletId: 5));

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('CatalogItemCard leadingImage', () {
    for (final entry in _sizes.entries) {
      testWidgets('fits: ${entry.key}, text x2', (tester) async {
        await _pump(
          tester,
          entry.value,
          2,
          CatalogItemCard(
            name: 'Powerade de frutas tropicales extra grande',
            description: 'Bebida hidratante para después del recreo',
            price: 1.1,
            originalPrice: 1.5,
            leadingImage: true,
            badges: const [CatalogBadge.info('Quedan 3')],
            onTap: () {},
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('\$1.10'), findsOneWidget);
        expect(find.text('Quedan 3'), findsOneWidget);
      });
    }
  });

  group('CatalogSearchField', () {
    testWidgets('the design style is a white outlined pill with its hint', (
      tester,
    ) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        CatalogSearchRow(
          searchController: TextEditingController(),
          onSearchChanged: (_) {},
          hintText: 'Buscar platos',
          outlined: true,
        ),
      );

      expect(find.text('Buscar platos'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      final decoration = field.decoration!;
      expect(decoration.fillColor, Colors.white);
      expect(tester.getSize(find.byType(TextField)).height, 48);
    });

    testWidgets('the default style (teacher, POS) is unchanged', (
      tester,
    ) async {
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        CatalogSearchRow(
          searchController: TextEditingController(),
          onSearchChanged: (_) {},
        ),
      );

      expect(find.text('Buscar...'), findsOneWidget);
      expect(tester.getSize(find.byType(TextField)).height, 42);
    });
  });

  group('CategoryFilterBar evenCircles', () {
    testWidgets('up to four options share the width and report taps', (
      tester,
    ) async {
      String? picked = 'sin elegir';
      await _pump(
        tester,
        _sizes['phone 390x844']!,
        1,
        CategoryFilterBar(
          categories: const ['Bar', 'Bebidas', 'Postres'],
          selected: null,
          style: CategoryFilterStyle.evenCircles,
          onSelected: (value) => picked = value,
        ),
      );

      expect(find.text('Todo'), findsOneWidget);
      expect(find.text('Categorías'), findsNothing);
      await tester.tap(find.text('Bebidas'));
      expect(picked, 'Bebidas');
      await tester.tap(find.text('Todo'));
      expect(picked, isNull);
    });

    for (final entry in _sizes.entries) {
      testWidgets('six options scroll without overflow: ${entry.key}', (
        tester,
      ) async {
        await _pump(
          tester,
          entry.value,
          2,
          CategoryFilterBar(
            categories: const [
              'Bar',
              'Bebidas',
              'Postres',
              'Snacks',
              'Almuerzo',
            ],
            selected: 'Bar',
            style: CategoryFilterStyle.evenCircles,
            onSelected: (_) {},
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
