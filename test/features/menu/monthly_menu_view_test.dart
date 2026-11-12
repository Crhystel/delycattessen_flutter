import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/core/widgets/floating_bubbles.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/providers/parent_menu_controller.dart';
import 'package:delycattessen_flutter/features/menu/screens/dish_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/member_menu_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/menu_dish_card.dart';
import 'package:delycattessen_flutter/features/menu/widgets/monthly_menu_ordering.dart';
import 'package:delycattessen_flutter/features/menu/widgets/monthly_menu_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/menu_screen_test_support.dart';

MenuDish _dish(int id, {bool allergic = false}) => MenuDish(
  id: id,
  name: 'Plato $id',
  description: 'Rico',
  price: 2.5,
  allergens: const ['Maní'],
  hasStudentAllergens: allergic,
);

MenuDay _day(
  int id,
  List<MenuDish> dishes, {
  bool blocked = false,
  String? reason,
}) => MenuDay(
  id: id,
  date: '2026-11-0$id',
  isBlockedByParentalControl: blocked,
  blockedReason: reason,
  dishes: dishes,
);

/// A loaded controller; the view under test never reads a ChildrenProvider.
Future<ParentMenuController> _loaded(
  WidgetTester tester,
  List<MenuDay> days,
) async {
  final menu = ParentMenuController(menuService: FakeMenuService(days));
  addTearDown(menu.dispose);
  await menu.load(5);
  return menu;
}

Future<void> _pump(
  WidgetTester tester,
  ParentMenuController menu, {
  bool showBackButton = false,
  MonthlyMenuOrdering? ordering,
  AllergenAudience audience = AllergenAudience.unknown,
  String? orderingFor,
  String? orderingPhotoUrl,
  Future<bool> Function()? onChangeChild,
  Widget? footer,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MonthlyMenuView(
        menu: menu,
        title: 'Menú del mes',
        showBackButton: showBackButton,
        onRefresh: () async {},
        onRetry: () {},
        ordering: ordering,
        allergenAudience: audience,
        orderingFor: orderingFor,
        orderingPhotoUrl: orderingPhotoUrl,
        onChangeChild: onChangeChild,
        footer: footer,
      ),
    ),
  );
  await settleMenu(tester);
}

Finder _shown(Finder finder) => finder.hitTestable();

/// A dish name painted on a card (not the one typed in the search field).
Finder _onCard(String name) =>
    find.descendant(of: find.byType(MenuDishCard), matching: find.text(name));

Finder get _scroll => find.byType(CustomScrollView);

/// The bubbles animate forever: advance time instead of pumpAndSettle.
Future<void> _advance(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 2));

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('read only', () {
    testWidgets('without ordering there is no Agregar button nor footer', (
      tester,
    ) async {
      final menu = await _loaded(tester, [
        _day(2, [_dish(1), _dish(2)]),
      ]);
      await _pump(tester, menu);

      expect(_shown(find.text('Plato 1')), findsOneWidget);
      expect(find.text('Agregar'), findsNothing);
      expect(find.text('Confirmar pedido'), findsNothing);
    });

    testWidgets('with ordering the dishes can be added and toggled', (
      tester,
    ) async {
      final toggled = <int>[];
      final menu = await _loaded(tester, [
        _day(2, [_dish(1)]),
      ]);
      await _pump(
        tester,
        menu,
        ordering: MonthlyMenuOrdering(
          onToggleDish: (dish) => toggled.add(dish.id),
          onAddDish: (dish, quantity) {},
        ),
      );

      await tester.tap(_shown(find.text('Agregar')));
      expect(toggled, [1]);
    });

    testWidgets('the dish detail only has "Añadir" when there is ordering', (
      tester,
    ) async {
      final added = <int>[];
      final menu = await _loaded(tester, [
        _day(2, [_dish(1)]),
      ]);
      await _pump(
        tester,
        menu,
        ordering: MonthlyMenuOrdering(
          onToggleDish: (_) {},
          onAddDish: (dish, quantity) => added.add(quantity),
        ),
      );

      await tester.tap(_shown(find.text('Plato 1')));
      await tester.pumpAndSettle();
      expect(find.byType(DishDetailScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.textContaining('Añadir'));
      await tester.pump();

      expect(added, [2]);
    });
  });

  group('bubbles', () {
    testWidgets('the view paints the design bubbles, and again behind the '
        'pinned band when folded', (tester) async {
      final menu = await _loaded(tester, [
        _day(2, [for (var i = 1; i <= 15; i++) _dish(i)]),
      ]);
      await _pump(tester, menu);

      expect(find.byType(FloatingBubbles), findsOneWidget);
      expect(
        tester.widget<FloatingBubbles>(find.byType(FloatingBubbles)).design,
        isTrue,
      );

      await tester.drag(_scroll, const Offset(0, -900));
      await _advance(tester);

      final bubbles = tester.widgetList<FloatingBubbles>(
        find.byType(FloatingBubbles),
      );
      expect(bubbles, hasLength(2));
      expect(bubbles.every((b) => b.design), isTrue);
    });

    testWidgets('the parent screen and the student screen both have them', (
      tester,
    ) async {
      await tester.pumpWidget(menuScreenApp());
      await settleMenu(tester);
      expect(find.byType(FloatingBubbles), findsOneWidget);

      final menu = ParentMenuController(
        menuService: FakeOwnMenuService([
          _day(2, [_dish(1), _dish(2)]),
        ]),
      );
      addTearDown(menu.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MemberMenuScreen(menuController: menu),
        ),
      );
      await settleMenu(tester);

      expect(find.byType(FloatingBubbles), findsOneWidget);
      expect(_shown(find.text('Menú del mes')), findsOneWidget);
      expect(_shown(find.text('2 platos')), findsOneWidget);
      expect(_shown(find.byType(TextField)), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('filters the dishes and is cleared when the day changes', (
      tester,
    ) async {
      final menu = await _loaded(tester, [
        _day(2, [for (var i = 1; i <= 12; i++) _dish(i)]),
        _day(3, [_dish(21), _dish(22)]),
      ]);
      await _pump(tester, menu);

      await tester.enterText(_shown(find.byType(TextField)), 'Plato 7');
      await tester.pump(const Duration(milliseconds: 400));
      await _advance(tester);
      expect(_onCard('Plato 7'), findsOneWidget);
      expect(_onCard('Plato 8'), findsNothing);
      expect(_shown(find.text('1 plato')), findsOneWidget);

      await tester.tap(_shown(find.text('3')));
      await _advance(tester);

      final field = tester.widget<TextField>(_shown(find.byType(TextField)));
      expect(field.controller!.text, isEmpty);
      expect(menu.searchQuery, isEmpty);
      expect(_onCard('Plato 21'), findsOneWidget);
      expect(_onCard('Plato 22'), findsOneWidget);
    });

    testWidgets('a search without results says so', (tester) async {
      final menu = await _loaded(tester, [
        _day(2, [_dish(1), _dish(2)]),
      ]);
      await _pump(tester, menu);

      await tester.enterText(_shown(find.byType(TextField)), 'sushi');
      await tester.pump(const Duration(milliseconds: 400));
      await _advance(tester);

      expect(find.text('No encontramos "sushi"'), findsOneWidget);
    });
  });

  group('back arrow', () {
    testWidgets('showBackButton shows it', (tester) async {
      final menu = await _loaded(tester, [
        _day(2, [_dish(1)]),
      ]);
      await _pump(tester, menu, showBackButton: true);

      expect(_shown(find.byTooltip('Volver')), findsOneWidget);
    });

    testWidgets('without showBackButton there is none', (tester) async {
      final menu = await _loaded(tester, [
        _day(2, [_dish(1)]),
      ]);
      await _pump(tester, menu);

      expect(find.byTooltip('Volver'), findsNothing);
    });
  });

  group('allergens', () {
    final days = [
      _day(2, [_dish(1, allergic: true)]),
    ];

    testWidgets('tapping a dish with allergens opens its detail, blocked', (
      tester,
    ) async {
      final menu = await _loaded(tester, days);
      await _pump(
        tester,
        menu,
        ordering: MonthlyMenuOrdering(
          onToggleDish: (_) {},
          onAddDish: (_, _) {},
        ),
        audience: const AllergenAudience.named('Ana'),
      );

      await tester.tap(_shown(find.text('Plato 1')));
      await tester.pumpAndSettle();

      expect(find.byType(DishDetailScreen), findsOneWidget);
      expect(find.text('Contiene maní'), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsOneWidget);
      expect(find.text('No disponible para Ana'), findsOneWidget);
      expect(find.textContaining('Añadir'), findsNothing);
    });

    testWidgets('the allergen chip of the card opens the same detail', (
      tester,
    ) async {
      final menu = await _loaded(tester, days);
      await _pump(tester, menu);

      await tester.tap(_shown(find.text('Contiene alérgenos')));
      await tester.pumpAndSettle();

      expect(find.byType(DishDetailScreen), findsOneWidget);
      expect(find.text('Maní'), findsOneWidget);
    });

    testWidgets('the detail gets the served day and the child to change', (
      tester,
    ) async {
      var changes = 0;
      final menu = await _loaded(tester, days);
      await _pump(
        tester,
        menu,
        ordering: MonthlyMenuOrdering(
          onToggleDish: (_) {},
          onAddDish: (_, _) {},
        ),
        orderingFor: 'Ana Pérez',
        onChangeChild: () async {
          changes++;
          return false;
        },
      );

      await tester.tap(_shown(find.text('Plato 1')));
      await tester.pumpAndSettle();

      expect(find.text('Dom 1 nov'), findsOneWidget); // day before the 2nd
      expect(find.text('Ana Pérez'), findsOneWidget);
      await tester.tap(find.text('Pedir para otro hijo'));
      await tester.pump();
      expect(changes, 1);
    });

    testWidgets('the detail gets the photo of the child', (tester) async {
      const url = 'https://example.test/ana.jpg';
      final menu = await _loaded(tester, days);
      await _pump(
        tester,
        menu,
        ordering: MonthlyMenuOrdering(
          onToggleDish: (_) {},
          onAddDish: (_, _) {},
        ),
        orderingFor: 'Ana Pérez',
        orderingPhotoUrl: url,
        onChangeChild: () async => false,
      );

      await tester.tap(_shown(find.text('Plato 1')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DishDetailScreen>(find.byType(DishDetailScreen))
            .orderingPhotoUrl,
        url,
      );
    });

    testWidgets('a dish without allergens can still be added from its detail', (
      tester,
    ) async {
      final added = <int>[];
      final menu = await _loaded(tester, [
        _day(2, [_dish(1)]),
      ]);
      await _pump(
        tester,
        menu,
        ordering: MonthlyMenuOrdering(
          onToggleDish: (_) {},
          onAddDish: (dish, quantity) => added.add(quantity),
        ),
        audience: const AllergenAudience.named('Ana'),
      );

      await tester.tap(_shown(find.text('Plato 1')));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedPurchaseBar), findsNothing);
      await tester.tap(find.textContaining('Añadir'));
      await tester.pump();
      expect(added, [1]);
    });
  });

  testWidgets('a blocked day shows its reason under the date', (tester) async {
    final menu = await _loaded(tester, [
      _day(2, [_dish(1)]),
      _day(3, [_dish(2)], blocked: true, reason: 'Sin servicio ese día.'),
    ]);
    await _pump(tester, menu);

    menu.selectDay(menu.days[1]);
    await settleMenu(tester);

    final date = _shown(find.text('Martes 3 de noviembre'));
    final reason = _shown(find.text('Sin servicio ese día.'));
    expect(date, findsOneWidget);
    expect(reason, findsOneWidget);
    expect(
      tester.getTopLeft(reason).dy,
      greaterThan(tester.getBottomLeft(date).dy - 1),
    );
  });

  group('folding header', () {
    Future<void> pumpWith(WidgetTester tester, int dishes) async {
      final menu = await _loaded(tester, [
        _day(2, [for (var i = 1; i <= dishes; i++) _dish(i)]),
      ]);
      await _pump(tester, menu);
      await tester.drag(_scroll, const Offset(0, -600));
      await _advance(tester);
    }

    testWidgets('with 3 dishes it folds completely', (tester) async {
      await pumpWith(tester, 3);

      expect(tester.takeException(), isNull);
      expect(_shown(find.text('Menú del mes')), findsNothing);
      expect(_shown(find.byType(TextField)), findsOneWidget);
    });

    testWidgets('with a single dish there is nothing to fold', (tester) async {
      await pumpWith(tester, 1);

      expect(_shown(find.text('Menú del mes')), findsOneWidget);
    });
  });
}
