import 'package:delycattessen_flutter/core/theme/app_theme.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/dish_detail_screen.dart';
import 'package:delycattessen_flutter/features/menu/utils/allergen_advisory.dart';
import 'package:delycattessen_flutter/features/menu/widgets/blocked_purchase_bar.dart';
import 'package:delycattessen_flutter/features/menu/widgets/child_ordering_row.dart';
import 'package:delycattessen_flutter/features/menu/widgets/quantity_add_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _dish = MenuDish(
  id: 1,
  name: 'Seco de pollo',
  description: 'Con arroz y ensalada',
  price: 3.5,
  allergens: const ['Maní', 'Lácteos'],
);

final _conflict = AllergenAdvisory.of(
  allergens: const ['Maní', 'Lácteos'],
  conflicts: const ['Maní'],
  audience: const AllergenAudience.named('Ana'),
);

final _safe = AllergenAdvisory.of(
  allergens: const ['Maní', 'Lácteos'],
  audience: const AllergenAudience.named('Ana'),
);

/// Opens the detail from a button so there is a route to pop.
Future<void> _open(
  WidgetTester tester, {
  Function(int)? onAdd,
  DateTime? servedDate,
  AllergenAdvisory advisory = const AllergenAdvisory(),
  String? orderingFor,
  Future<bool> Function()? onChangeChild,
  MenuDish? dish,
}) async {
  tester.view.physicalSize = const Size(411, 891);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DishDetailScreen(
                  dish: dish ?? _dish,
                  onAdd: onAdd,
                  servedDate: servedDate,
                  advisory: advisory,
                  orderingFor: orderingFor,
                  onChangeChild: onChangeChild,
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('dates', () {
    testWidgets('shows the serving day and the day before as the deadline', (
      tester,
    ) async {
      await _open(tester, servedDate: DateTime(2026, 11, 10));

      expect(find.text('Se sirve el'), findsOneWidget);
      expect(find.text('Martes 10 nov'), findsOneWidget);
      expect(find.text('Pide hasta'), findsOneWidget);
      expect(find.text('Lun 9 nov'), findsOneWidget);
    });

    testWidgets('the deadline crosses the month', (tester) async {
      await _open(tester, servedDate: DateTime(2026, 12, 1));

      expect(find.text('Lun 30 nov'), findsOneWidget);
    });

    testWidgets('without a date there are no date cards', (tester) async {
      await _open(tester);

      expect(find.text('Se sirve el'), findsNothing);
      expect(find.text('Pide hasta'), findsNothing);
    });
  });

  testWidgets('shows the name, the description and the price', (tester) async {
    await _open(tester);

    expect(find.text('Menú del mes'), findsOneWidget);
    expect(find.text('Seco de pollo'), findsOneWidget);
    expect(find.text('Con arroz y ensalada'), findsOneWidget);
    expect(find.text('\$3.50'), findsOneWidget);
  });

  group('allergens', () {
    testWidgets('with a conflict: red box, chips and a blocked bar', (
      tester,
    ) async {
      var changed = 0;
      await _open(
        tester,
        onAdd: (_) {},
        advisory: _conflict,
        orderingFor: 'Ana Pérez',
        onChangeChild: () async {
          changed++;
          return false;
        },
      );

      expect(find.text('Alérgenos'), findsOneWidget);
      expect(find.text('Maní'), findsOneWidget);
      expect(find.text('Lácteos'), findsOneWidget);
      expect(find.text('Contiene maní'), findsOneWidget);
      expect(
        find.text(
          'Ana tiene registrada esta alergia, por eso este plato no se le '
          'puede vender.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BlockedPurchaseBar), findsOneWidget);
      expect(find.text('No disponible para Ana'), findsOneWidget);
      expect(find.byType(QuantityAddBar), findsNothing);
      expect(find.textContaining('Añadir'), findsNothing);

      await tester.tap(find.text('Pedir para otro hijo'));
      await tester.pump();
      expect(changed, 1);
    });

    testWidgets('without a way to change child the bar has no link', (
      tester,
    ) async {
      await _open(tester, onAdd: (_) {}, advisory: _conflict);

      expect(find.text('No disponible para Ana'), findsOneWidget);
      expect(find.text('Pedir para otro hijo'), findsNothing);
    });

    testWidgets('without a conflict: green box and the quantity bar', (
      tester,
    ) async {
      int? added;
      await _open(tester, onAdd: (qty) => added = qty, advisory: _safe);

      expect(
        find.text('Ana no tiene registradas estas alergias.'),
        findsOneWidget,
      );
      expect(find.textContaining('Contiene'), findsNothing);
      expect(find.byType(BlockedPurchaseBar), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.textContaining('Añadir'));
      await tester.pumpAndSettle();

      expect(added, 2);
      expect(find.byType(DishDetailScreen), findsNothing);
    });

    testWidgets('read only: the notice shows but there is no bar', (
      tester,
    ) async {
      await _open(tester, advisory: _conflict);

      expect(find.text('Contiene maní'), findsOneWidget);
      expect(find.byType(BlockedPurchaseBar), findsNothing);
      expect(find.byType(QuantityAddBar), findsNothing);
    });

    testWidgets('the student sees "Tienes registrada" and "para ti"', (
      tester,
    ) async {
      await _open(
        tester,
        onAdd: (_) {},
        advisory: AllergenAdvisory.of(
          allergens: const ['Maní'],
          conflicts: const ['Maní'],
          audience: AllergenAudience.self,
        ),
      );

      expect(
        find.text(
          'Tienes registrada esta alergia, por eso este plato no se te puede '
          'vender.',
        ),
        findsOneWidget,
      );
      expect(find.text('No disponible para ti'), findsOneWidget);
    });

    testWidgets('an unknown audience only lists the chips', (tester) async {
      await _open(
        tester,
        advisory: AllergenAdvisory.of(allergens: const ['Maní', 'Lácteos']),
      );

      expect(find.text('Maní'), findsOneWidget);
      expect(find.textContaining('registrada'), findsNothing);
      expect(find.textContaining('Contiene'), findsNothing);
    });

    testWidgets('a dish without allergens says so', (tester) async {
      await _open(
        tester,
        dish: MenuDish(id: 2, name: 'Agua', description: '', price: 1),
      );

      expect(find.text('Sin alérgenos registrados'), findsOneWidget);
    });

    testWidgets('the default advisory still lists the dish allergens', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Maní'), findsOneWidget);
      expect(find.text('Sin alérgenos registrados'), findsNothing);
    });
  });

  group('child', () {
    testWidgets('shows who it is ordered for and "Cambiar"', (tester) async {
      await _open(
        tester,
        orderingFor: 'Ana Pérez',
        onChangeChild: () async => false,
      );

      expect(find.byType(ChildOrderingRow), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
    });

    testWidgets('without a callback there is no row', (tester) async {
      await _open(tester, orderingFor: 'Ana Pérez');
      expect(find.byType(ChildOrderingRow), findsNothing);
    });

    testWidgets('"Cambiar" closes the detail when the child changed', (
      tester,
    ) async {
      await _open(
        tester,
        orderingFor: 'Ana Pérez',
        onChangeChild: () async => true,
      );

      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();

      expect(find.byType(DishDetailScreen), findsNothing);
    });

    testWidgets('"Cambiar" keeps the detail when the child did not change', (
      tester,
    ) async {
      var calls = 0;
      await _open(
        tester,
        orderingFor: 'Ana Pérez',
        onChangeChild: () async {
          calls++;
          return false;
        },
      );

      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.byType(DishDetailScreen), findsOneWidget);
    });

    testWidgets('"Pedir para otro hijo" closes it when the child changed', (
      tester,
    ) async {
      await _open(
        tester,
        onAdd: (_) {},
        advisory: _conflict,
        onChangeChild: () async => true,
      );

      await tester.tap(find.text('Pedir para otro hijo'));
      await tester.pumpAndSettle();

      expect(find.byType(DishDetailScreen), findsNothing);
    });
  });
}
