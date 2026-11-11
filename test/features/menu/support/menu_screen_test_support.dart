import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/providers/parent_menu_controller.dart';
import 'package:delycattessen_flutter/features/menu/screens/menu_screen.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final testChild = Child(
  id: 5,
  firstName: 'Ana',
  lastName: 'Pérez',
  institutionName: 'Martim Cereré',
  balance: 5,
);

/// Days 2 to 6 of November 2026; day 4 is blocked by the parental control.
/// The first day has many dishes so the page scrolls on a phone.
List<MenuDay> testMenuDays() => [
  for (var day = 2; day <= 6; day++)
    MenuDay(
      id: day,
      date: '2026-11-0$day',
      isBlockedByParentalControl: day == 4,
      dishes: [
        for (var i = 1; i <= (day == 2 ? 15 : 2); i++)
          MenuDish(
            id: day * 100 + i,
            name: 'Plato $i del día $day',
            description: 'Rico',
            price: 2.5,
          ),
      ],
    ),
];

class _FakeChildrenAuth extends AuthService {
  @override
  Future<List<Child>> getChildren() async => [testChild];
}

class FakeMenuService extends MenuService {
  FakeMenuService(this.days);

  final List<MenuDay> days;

  @override
  Future<List<MenuDay>> getStudentMonthlyMenu(int studentId) async => days;
}

/// Same days, but for the logged-in student (the read-only menu).
class FakeOwnMenuService extends FakeMenuService {
  FakeOwnMenuService(super.days);

  @override
  Future<List<MenuDay>> getOwnMonthlyMenu() async => days;
}

/// The monthly menu screen with a simulated service, ready to pump.
Widget menuScreenApp({
  List<MenuDay>? days,
  bool embedded = true,
  double textScale = 1,
}) => ChangeNotifierProvider(
  create: (_) => ChildrenProvider(authService: _FakeChildrenAuth()),
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: MenuScreen(
      embedded: embedded,
      headerAccessory: const Text('selector menu-productos'),
      menuController: ParentMenuController(
        menuService: FakeMenuService(days ?? testMenuDays()),
      ),
    ),
  ),
);

/// Gives the screen time to load the children and the menu.
Future<void> settleMenu(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}
