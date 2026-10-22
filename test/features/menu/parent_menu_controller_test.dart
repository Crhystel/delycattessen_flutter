import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/providers/parent_menu_controller.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:flutter_test/flutter_test.dart';

MenuDish _dish(int id, String name, double price) =>
    MenuDish(id: id, name: name, description: '', price: price);

MenuDay _day(int id, String date, List<MenuDish> dishes) => MenuDay(
  id: id,
  date: date,
  isBlockedByParentalControl: false,
  dishes: dishes,
);

class _FakeMenuService extends MenuService {
  _FakeMenuService(this.days);

  List<MenuDay> days;
  Object? error;

  @override
  Future<List<MenuDay>> getStudentMonthlyMenu(int studentId) async {
    if (error != null) throw error!;
    return days;
  }
}

void main() {
  final monday = _day(1, '2026-10-19', [
    _dish(10, 'Pollo', 3.0),
    _dish(11, 'Arroz con huevo', 2.0),
  ]);
  final tuesday = _day(2, '2026-10-20', [_dish(20, 'Pasta', 4.0)]);

  ParentMenuController build() =>
      ParentMenuController(menuService: _FakeMenuService([monday, tuesday]));

  group('load', () {
    test('selects the first day by default', () async {
      final menu = build();
      await menu.load(1);

      expect(menu.isLoading, isFalse);
      expect(menu.days, hasLength(2));
      expect(menu.selectedDay?.id, 1);
    });

    test('selects the initial date when the menu has it', () async {
      final menu = build();
      await menu.load(1, initialDate: DateTime(2026, 10, 20));

      expect(menu.selectedDay?.id, 2);
    });

    test('keeps a clean error message when loading fails', () async {
      final service = _FakeMenuService([])..error = Exception('Sin conexión');
      final menu = ParentMenuController(menuService: service);

      await menu.load(1);

      expect(menu.errorMessage, 'Sin conexión');
      expect(menu.isLoading, isFalse);
    });
  });

  group('cart', () {
    test('adds quantities and computes total and count', () async {
      final menu = build();
      await menu.load(1);

      menu.addToCart(10, 2);
      menu.addToCart(10, 1);
      menu.addToCart(11, 1);

      expect(menu.cart, {10: 3, 11: 1});
      expect(menu.total, 11.0);
      expect(menu.cartItemCount, 4);
      expect(menu.hasCart, isTrue);
    });

    test('changing day empties the cart and the search', () async {
      final menu = build();
      await menu.load(1);
      menu.addToCart(10, 1);
      menu.setSearchQuery('pollo');

      menu.selectDay(tuesday);

      expect(menu.selectedDay?.id, 2);
      expect(menu.hasCart, isFalse);
      expect(menu.searchQuery, isEmpty);
    });

    test('replaceCart overwrites and clearCart empties', () async {
      final menu = build();
      await menu.load(1);
      menu.addToCart(10, 1);

      menu.replaceCart({11: 2});
      expect(menu.cart, {11: 2});

      menu.clearCart();
      expect(menu.hasCart, isFalse);
    });

    test('the exposed cart cannot be modified from outside', () async {
      final menu = build();
      await menu.load(1);

      expect(() => menu.cart[10] = 1, throwsUnsupportedError);
    });
  });

  group('search', () {
    test('filters dishes ignoring case and spaces', () async {
      final menu = build();
      await menu.load(1);

      menu.setSearchQuery('  POLLO ');

      expect(menu.visibleDishes.map((d) => d.id), [10]);
    });

    test('shows every dish with an empty query', () async {
      final menu = build();
      await menu.load(1);

      expect(menu.visibleDishes, hasLength(2));
    });
  });

  test('does not notify after being disposed', () async {
    final menu = build();
    final loading = menu.load(1);
    menu.dispose();

    await expectLater(loading, completes);
  });
}
