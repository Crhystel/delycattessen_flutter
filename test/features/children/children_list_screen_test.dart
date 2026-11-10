import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/children/screens/children_list_screen.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/core/utils/date_formatter.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final _child = Child(
  id: 5,
  firstName: 'Ana',
  lastName: 'Pérez',
  institutionName: 'Martim Cereré',
  balance: 20,
);

class _FakeAuth extends AuthService {
  @override
  Future<List<Child>> getChildren() async => [_child];
}

/// Simulated menu: [days] and [combos] are what the child's school offers.
class _FakeMenu extends MenuService {
  _FakeMenu({this.days = const [], this.combos = const []});

  final List<MenuDay> days;
  final List<Combo> combos;

  @override
  Future<List<MenuDay>> getStudentMonthlyMenu(int studentId) async => days;

  @override
  Future<CatalogOffers> getActiveOffers({int? studentId}) async =>
      CatalogOffers(combos: combos);
}

/// Records the order of the calls to prove they are not chained.
class _SlowMenu extends MenuService {
  final started = <String>[];
  bool finishedBeforeOtherStarted = false;
  bool _menuDone = false;
  bool _offersDone = false;

  @override
  Future<List<MenuDay>> getStudentMonthlyMenu(int studentId) async {
    started.add('menu');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (_offersDone && !started.contains('offers')) {
      finishedBeforeOtherStarted = true;
    }
    _menuDone = true;
    return const [];
  }

  @override
  Future<CatalogOffers> getActiveOffers({int? studentId}) async {
    if (_menuDone && !started.contains('offers')) {
      finishedBeforeOtherStarted = true;
    }
    started.add('offers');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    _offersDone = true;
    return CatalogOffers.empty;
  }
}

Future<void> _pumpHome(
  WidgetTester tester,
  MenuService menu, {
  void Function(int)? onOrder,
  VoidCallback? onProducts,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ChildrenProvider(authService: _FakeAuth()),
      child: MaterialApp(
        home: ChildrenListScreen(
          userName: 'Crhystel',
          menuService: menu,
          onOrderForChild: onOrder,
          onOpenProducts: onProducts,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows the Menú and Productos sections even with no data', (
    tester,
  ) async {
    await _pumpHome(tester, _FakeMenu());

    expect(find.text('Menú'), findsOneWidget);
    expect(find.text('Ver menú'), findsOneWidget);
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Ver productos'), findsOneWidget);
    expect(
      find.text('Aún no hay platillos publicados para los próximos días.'),
      findsOneWidget,
    );
    expect(
      find.text('Mira los productos y combos disponibles.'),
      findsOneWidget,
    );
    expect(find.textContaining('Próximo'), findsNothing);
  });

  testWidgets('with data the Menú shows the dish and Productos the combo', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      _FakeMenu(
        days: [
          MenuDay(
            id: 1,
            date: '2026-11-10',
            isBlockedByParentalControl: false,
            dishes: [
              MenuDish(
                id: 1,
                name: 'Pollo asado',
                description: 'Con arroz',
                price: 3.5,
              ),
            ],
          ),
        ],
        combos: [
          Combo(
            id: 1,
            name: 'Promo barata',
            price: 2,
            regularPrice: 7,
            endDate: DateTime(2026, 11, 12),
          ),
        ],
      ),
    );

    expect(find.text('Pollo asado'), findsOneWidget);
    expect(find.text('Preordenar'), findsOneWidget);
    expect(find.textContaining('Promo barata'), findsOneWidget);
    expect(find.text('COMBO'), findsOneWidget);
  });

  testWidgets('the section links open the Menú and Productos tabs', (
    tester,
  ) async {
    int? ordered;
    var products = 0;
    await _pumpHome(
      tester,
      _FakeMenu(),
      onOrder: (id) => ordered = id,
      onProducts: () => products++,
    );

    await tester.tap(find.text('Ver menú'));
    await tester.tap(find.text('Ver productos'));

    expect(ordered, 5);
    expect(products, 1);
  });
  MenuDay dayOn(DateTime date) => MenuDay(
    id: 1,
    date: DateFormatter.toIsoDate(date),
    isBlockedByParentalControl: false,
    dishes: [
      MenuDish(
        id: 1,
        name: 'Pollo asado',
        description: 'Con arroz',
        price: 3.5,
      ),
    ],
  );

  testWidgets('the first day being tomorrow titles the section "Mañana"', (
    tester,
  ) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    await _pumpHome(tester, _FakeMenu(days: [dayOn(tomorrow)]));

    expect(find.text('Mañana en el menú'), findsOneWidget);
    expect(find.text('Próximo menú'), findsNothing);
    expect(
      find.text(
        '${DateFormatter.weekdayName(tomorrow)[0].toUpperCase()}'
        '${DateFormatter.weekdayName(tomorrow).substring(1)} ${tomorrow.day}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a later first day titles the section "Próximo menú"', (
    tester,
  ) async {
    final now = DateTime.now();
    final later = DateTime(now.year, now.month, now.day + 4);
    await _pumpHome(tester, _FakeMenu(days: [dayOn(later)]));

    expect(find.text('Próximo menú'), findsOneWidget);
    expect(find.text('Mañana en el menú'), findsNothing);
    expect(
      find.text(DateFormatter.formatLongCapitalized(later)),
      findsOneWidget,
    );
  });

  testWidgets('the menu and the offers are requested at the same time', (
    tester,
  ) async {
    final menu = _SlowMenu();
    await _pumpHome(tester, menu);

    // Both calls started before either one answered (not one after the other).
    expect(menu.started, containsAll(['menu', 'offers']));
    expect(menu.finishedBeforeOtherStarted, isFalse);
  });
}
