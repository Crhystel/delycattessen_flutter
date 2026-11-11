import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/providers/parent_menu_controller.dart';
import 'package:delycattessen_flutter/features/menu/screens/dish_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/screens/menu_screen.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/menu_screen_test_support.dart' show settleMenu;

final _ana = Child(
  id: 5,
  firstName: 'Ana',
  lastName: 'Pérez',
  institutionName: 'Martim Cereré',
  balance: 20,
);

final _luis = Child(
  id: 6,
  firstName: 'Luis',
  lastName: 'Gómez',
  institutionName: 'Martim Cereré',
  balance: 20,
);

class _FakeAuth extends AuthService {
  _FakeAuth(this.children);

  final List<Child> children;

  @override
  Future<List<Child>> getChildren() async => children;
}

/// Ana is allergic to the peanuts of the dish; Luis is not.
class _FakeMenuService extends MenuService {
  final loaded = <int>[];

  @override
  Future<List<MenuDay>> getStudentMonthlyMenu(int studentId) async {
    loaded.add(studentId);
    final allergic = studentId == _ana.id;
    return [
      MenuDay(
        id: 2,
        date: '2026-11-02',
        isBlockedByParentalControl: false,
        dishes: [
          MenuDish(
            id: 1,
            name: 'Seco de maní',
            description: 'Con arroz',
            price: 3,
            allergens: const ['Maní'],
            conflictingAllergens: allergic ? const ['Maní'] : const [],
            hasStudentAllergens: allergic,
          ),
        ],
      ),
    ];
  }
}

Future<_FakeMenuService> _pump(
  WidgetTester tester,
  List<Child> children,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = _FakeMenuService();
  final menu = ParentMenuController(menuService: service);
  addTearDown(menu.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ChildrenProvider(authService: _FakeAuth(children)),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: MenuScreen(embedded: true, menuController: menu),
      ),
    ),
  );
  await settleMenu(tester);
  return service;
}

Finder _shown(Finder finder) => finder.hitTestable();

Future<void> _openDish(WidgetTester tester) async {
  await tester.tap(_shown(find.text('Seco de maní')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a dish with the child allergens opens a blocked detail', (
    tester,
  ) async {
    await _pump(tester, [_ana]);

    await _openDish(tester);

    expect(find.byType(DishDetailScreen), findsOneWidget);
    expect(find.text('Contiene maní'), findsOneWidget);
    expect(
      find.text(
        'Ana tiene registrada esta alergia, por eso este plato no se le '
        'puede vender.',
      ),
      findsOneWidget,
    );
    expect(find.text('No disponible para Ana'), findsOneWidget);
    expect(find.textContaining('Añadir'), findsNothing);
    // One child only: nobody else to order for.
    expect(find.text('Pedir para otro hijo'), findsNothing);
    expect(find.byType(BlockedPurchaseBar), findsOneWidget);
  });

  testWidgets('"Pedir para otro hijo" switches the child and closes the '
      'detail', (tester) async {
    final service = await _pump(tester, [_ana, _luis]);
    await _openDish(tester);

    await tester.tap(find.text('Pedir para otro hijo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Para quién estás pidiendo?'), findsOneWidget);

    await tester.tap(find.text('Luis Gómez'));
    await tester.pumpAndSettle();

    expect(find.byType(DishDetailScreen), findsNothing);
    expect(service.loaded, [5, 6]);

    // The dish reloaded for Luis opens without a conflict.
    await _openDish(tester);
    expect(find.byType(BlockedPurchaseBar), findsNothing);
    expect(find.text('Luis no tiene registrada esta alergia.'), findsOneWidget);
  });

  testWidgets('closing the picker without choosing keeps the detail', (
    tester,
  ) async {
    await _pump(tester, [_ana, _luis]);
    await _openDish(tester);

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    expect(find.byType(DishDetailScreen), findsOneWidget);
  });
}
