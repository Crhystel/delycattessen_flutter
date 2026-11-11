import 'package:cached_network_image/cached_network_image.dart';
import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/providers/parent_menu_controller.dart';
import 'package:delycattessen_flutter/features/menu/screens/dish_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/member_menu_screen.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:delycattessen_flutter/features/menu/widgets/menu_dish_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/menu_screen_test_support.dart' show settleMenu;

MenuDish _dish({bool allergic = false}) => MenuDish(
  id: 1,
  name: 'Seco de pollo',
  description: 'Con arroz',
  price: 3.5,
  allergens: const ['Maní'],
  hasStudentAllergens: allergic,
);

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light(), home: child);

class _FakeMenuService extends MenuService {
  _FakeMenuService({this.days = const [], this.error});

  final List<MenuDay> days;
  final Object? error;
  int calls = 0;

  @override
  Future<List<MenuDay>> getOwnMonthlyMenu() async {
    calls++;
    if (error != null) throw error!;
    return days;
  }
}

void main() {
  group('MenuDishCard', () {
    testWidgets('without onToggle it is read only: no add button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: MenuDishCard(
              dish: _dish(),
              onTap: () {},
              onShowAllergens: () {},
            ),
          ),
        ),
      );

      expect(find.text('Seco de pollo'), findsOneWidget);
      expect(find.text('Ver alérgenos'), findsOneWidget);
      expect(find.text('Agregar'), findsNothing);
      expect(find.text('Agregado'), findsNothing);
    });

    testWidgets('its photo caches a single side so it is not stretched', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: MenuDishCard(
              dish: MenuDish(
                id: 1,
                name: 'Seco de pollo',
                description: 'Con arroz',
                price: 3.5,
                imageUrl: 'https://example.test/seco.jpg',
              ),
              onTap: () {},
              onShowAllergens: () {},
            ),
          ),
        ),
      );

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.fit, BoxFit.cover);
      expect(
        [image.memCacheWidth, image.memCacheHeight].where((s) => s != null),
        hasLength(1),
      );
    });

    testWidgets('with onToggle the parent flow still shows and fires Agregar', (
      tester,
    ) async {
      var toggled = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: MenuDishCard(
              dish: _dish(),
              inCart: false,
              onTap: () {},
              onToggle: () => toggled++,
              onShowAllergens: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Agregar'));
      expect(toggled, 1);
    });
  });

  group('DishDetailScreen', () {
    testWidgets('without onAdd there is no quantity bar nor add button', (
      tester,
    ) async {
      await tester.pumpWidget(_app(DishDetailScreen(dish: _dish())));

      expect(find.text('Seco de pollo'), findsOneWidget);
      expect(find.text('Alérgenos identificados'), findsOneWidget);
      expect(find.text('Maní'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
      expect(find.textContaining('Añadir'), findsNothing);
    });

    testWidgets('with onAdd the parent flow keeps the quantity bar', (
      tester,
    ) async {
      int? added;
      await tester.pumpWidget(
        _app(DishDetailScreen(dish: _dish(), onAdd: (qty) => added = qty)),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.textContaining('Añadir'));
      await tester.pump();

      expect(added, 2);
    });
  });

  group('MemberMenuScreen', () {
    MenuDay day(int id, String date, {bool blocked = false}) => MenuDay(
      id: id,
      date: date,
      isBlockedByParentalControl: blocked,
      blockedReason: blocked ? 'Bloqueado por el control parental.' : null,
      dishes: [_dish(allergic: id == 1)],
    );

    Future<void> pump(WidgetTester tester, _FakeMenuService service) async {
      final controller = ParentMenuController(menuService: service);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(MemberMenuScreen(menuController: controller)),
      );
      await settleMenu(tester);
    }

    // The collapsing header measures itself with invisible copies: look only
    // at what is painted.
    Finder shown(Finder finder) => finder.hitTestable();

    testWidgets('shows the days and dishes without any ordering action', (
      tester,
    ) async {
      await pump(
        tester,
        _FakeMenuService(days: [day(1, '2026-11-10'), day(2, '2026-11-11')]),
      );

      expect(shown(find.text('Menú del mes')), findsOneWidget);
      expect(shown(find.text('Seco de pollo')), findsOneWidget);
      expect(shown(find.text('Contiene alérgenos')), findsOneWidget);
      expect(find.text('Agregar'), findsNothing);
      expect(find.text('Confirmar pedido'), findsNothing);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
    });

    testWidgets('a blocked day can still be read and shows its reason', (
      tester,
    ) async {
      await pump(
        tester,
        _FakeMenuService(
          days: [day(1, '2026-11-10'), day(2, '2026-11-11', blocked: true)],
        ),
      );

      await tester.tap(shown(find.byIcon(Icons.lock_outline)));
      await settleMenu(tester);

      expect(
        shown(find.text('Bloqueado por el control parental.')),
        findsOneWidget,
      );
      expect(shown(find.text('Seco de pollo')), findsOneWidget);
    });

    testWidgets('opening a dish shows its detail without ordering', (
      tester,
    ) async {
      await pump(tester, _FakeMenuService(days: [day(1, '2026-11-10')]));

      await tester.tap(shown(find.text('Seco de pollo')));
      await tester.pumpAndSettle();

      expect(find.byType(DishDetailScreen), findsOneWidget);
      expect(find.textContaining('Añadir'), findsNothing);
    });

    testWidgets('shows the error with a retry that reloads', (tester) async {
      final service = _FakeMenuService(error: Exception('Sin conexión'));
      await pump(tester, service);

      expect(find.text('No pudimos cargar el menú'), findsOneWidget);
      expect(find.text('Sin conexión'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await settleMenu(tester);
      expect(service.calls, 2);
    });

    testWidgets('shows an empty state when no menu is published', (
      tester,
    ) async {
      await pump(tester, _FakeMenuService());

      expect(
        find.text('Aún no hay un menú publicado para la institución.'),
        findsOneWidget,
      );
    });
  });
}
