import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/menu/providers/parent_menu_controller.dart';
import 'package:delycattessen_flutter/features/menu/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/menu_screen_test_support.dart';

final _ana = Child(
  id: 5,
  firstName: 'Ana',
  lastName: 'Pérez',
  institutionName: 'Martim Cereré',
  balance: 5,
);

final _luis = Child(
  id: 6,
  firstName: 'Luis',
  lastName: 'Pérez',
  institutionName: 'Martim Cereré',
  balance: 8,
);

class _TwoChildrenAuth extends AuthService {
  List<Child> children = [_ana, _luis];

  @override
  Future<List<Child>> getChildren() async => children;

  @override
  Future<void> removeChild(int studentId, String parentPassword) async {
    children = children.where((c) => c.id != studentId).toList();
  }
}

/// The same tree on every call, so pumping it again updates the screen in
/// place (as the shell does when Inicio asks for another day).
Widget _app(
  ChildrenProvider provider,
  ParentMenuController controller, {
  DateTime? initialDate,
  Object? request,
}) => ChangeNotifierProvider.value(
  value: provider,
  child: MaterialApp(
    home: MenuScreen(
      embedded: true,
      initialDate: initialDate,
      dateRequest: request,
      menuController: controller,
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'a new initialDate opens that day without recreating the screen',
    (tester) async {
      _phone(tester);
      final provider = ChildrenProvider(authService: _TwoChildrenAuth());
      final controller = ParentMenuController(
        menuService: FakeMenuService(testMenuDays()),
      );
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        _app(provider, controller, initialDate: DateTime(2026, 11, 3)),
      );
      await settleMenu(tester);
      expect(find.text('Plato 1 del día 3'), findsOneWidget);
      final state = tester.state(find.byType(MenuScreen));

      await tester.pumpWidget(
        _app(provider, controller, initialDate: DateTime(2026, 11, 5)),
      );
      await tester.pump();

      expect(find.text('Plato 1 del día 5'), findsOneWidget);
      expect(find.text('Plato 1 del día 3'), findsNothing);
      expect(tester.state(find.byType(MenuScreen)), same(state));
    },
  );

  testWidgets('the same date asked again after browsing opens it again', (
    tester,
  ) async {
    _phone(tester);
    final provider = ChildrenProvider(authService: _TwoChildrenAuth());
    final controller = ParentMenuController(
      menuService: FakeMenuService(testMenuDays()),
    );
    addTearDown(provider.dispose);
    final date = DateTime(2026, 11, 3);

    await tester.pumpWidget(
      _app(provider, controller, initialDate: date, request: 1),
    );
    await settleMenu(tester);
    // The parent browses to another day.
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.text('Plato 1 del día 5'), findsOneWidget);

    // Inicio asks for day 3 again: same date, new request.
    await tester.pumpWidget(
      _app(provider, controller, initialDate: date, request: 2),
    );
    await tester.pump();

    expect(find.text('Plato 1 del día 3'), findsOneWidget);
  });

  testWidgets(
    '"Conservar" brings the global selection back to the menu child',
    (tester) async {
      _phone(tester);
      final provider = ChildrenProvider(authService: _TwoChildrenAuth());
      final controller = ParentMenuController(
        menuService: FakeMenuService(testMenuDays()),
      );
      addTearDown(provider.dispose);
      await tester.pumpWidget(_app(provider, controller));
      await settleMenu(tester);
      expect(provider.selectedChild!.id, _ana.id);

      // A dish in the cart, then another child is picked elsewhere in the app.
      await tester.tap(find.text('Agregar').first);
      await tester.pump();
      provider.select(_luis.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Cambiar de estudiante'), findsOneWidget);

      await tester.tap(find.text('Conservar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(provider.selectedChild!.id, _ana.id);
      expect(controller.hasCart, isTrue);
    },
  );

  testWidgets('"Cambiar y vaciar" switches to the new child and clears', (
    tester,
  ) async {
    _phone(tester);
    final provider = ChildrenProvider(authService: _TwoChildrenAuth());
    final controller = ParentMenuController(
      menuService: FakeMenuService(testMenuDays()),
    );
    addTearDown(provider.dispose);
    await tester.pumpWidget(_app(provider, controller));
    await settleMenu(tester);

    await tester.tap(find.text('Agregar').first);
    await tester.pump();
    provider.select(_luis.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cambiar y vaciar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(provider.selectedChild!.id, _luis.id);
    expect(controller.hasCart, isFalse);
  });

  testWidgets('a removed child is replaced without asking about the cart', (
    tester,
  ) async {
    _phone(tester);
    final provider = ChildrenProvider(authService: _TwoChildrenAuth());
    final controller = ParentMenuController(
      menuService: FakeMenuService(testMenuDays()),
    );
    addTearDown(provider.dispose);
    await tester.pumpWidget(_app(provider, controller));
    await settleMenu(tester);
    expect(provider.selectedChild!.id, _ana.id);

    await tester.tap(find.text('Agregar').first);
    await tester.pump();
    expect(controller.hasCart, isTrue);

    await provider.removeChild(_ana.id, parentPassword: 'Parent-Passw0rd!');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cambiar de estudiante'), findsNothing);
    expect(find.text('Conservar'), findsNothing);
    expect(provider.selectedChild!.id, _luis.id);
    expect(controller.hasCart, isFalse);
  });
}
