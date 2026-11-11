import 'dart:async';

import 'package:delycattessen_flutter/features/auth/models/auth_models.dart';
import 'package:delycattessen_flutter/features/auth/services/auth_service.dart';
import 'package:delycattessen_flutter/features/children/providers/children_provider.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/screens/orders_screen.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:delycattessen_flutter/features/menu/utils/orders_reload_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

OrderEntry _order(
  int id, {
  required int studentId,
  required String dish,
  bool pending = false,
}) => OrderEntry(
  id: id,
  studentId: studentId,
  studentName: 'Hijo $studentId',
  createdAt: DateTime(2026, 11, 3, 12),
  status: pending ? PreOrderStatus.pending : PreOrderStatus.delivered,
  statusDisplay: pending ? 'Pendiente' : 'Entregado',
  deliveryDate: pending ? '2026-11-10' : '',
  totalAmount: 3.5,
  items: [
    PreOrderItemDetail(
      id: id,
      dishId: id,
      dishName: dish,
      quantity: 1,
      priceAtPurchase: 3.5,
    ),
  ],
  origin: pending ? OrderOrigin.preorder : OrderOrigin.pointOfSale,
);

/// Counts requests and can hold the answers back to test their order.
class _FakeMenuService extends MenuService {
  final List<int?> preOrderCalls = [];
  final List<int?> purchaseCalls = [];

  /// Called for each request; return a future to delay the answer.
  Future<List<OrderEntry>> Function(int? studentId)? purchases;

  @override
  Future<List<PreOrderSummary>> getPreOrders({int? studentId}) async {
    preOrderCalls.add(studentId);
    return [];
  }

  @override
  Future<List<OrderEntry>> getPurchases({int? studentId}) {
    purchaseCalls.add(studentId);
    final handler = purchases;
    if (handler != null) return handler(studentId);
    return Future.value([
      _order(1, studentId: studentId ?? 0, dish: 'Helado'),
      _order(2, studentId: studentId ?? 0, dish: 'Crepes', pending: true),
    ]);
  }
}

class _FakeAuth extends AuthService {
  @override
  Future<List<Child>> getChildren() async => [
    Child(id: 5, firstName: 'Ana', lastName: 'Pérez', institutionName: 'X'),
    Child(id: 6, firstName: 'Luis', lastName: 'Pérez', institutionName: 'X'),
  ];
}

Widget _app(
  _FakeMenuService service, {
  bool isActive = true,
  ChildrenProvider? provider,
}) {
  final screen = MaterialApp(
    home: OrdersScreen(
      studentId: provider == null ? 5 : null,
      embedded: provider != null,
      isActive: isActive,
      menuService: service,
    ),
  );
  if (provider == null) return screen;
  return ChangeNotifierProvider.value(value: provider, child: screen);
}

void _phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('filters with a three-option switch', (tester) async {
    _phoneView(tester);
    await tester.pumpWidget(_app(_FakeMenuService()));
    await tester.pumpAndSettle();

    // Todos: both sections.
    expect(find.text('Pendientes'), findsNWidgets(2)); // option + section
    expect(find.text('Entregados'), findsNWidgets(2));
    expect(find.text('1× Crepes'), findsOneWidget);
    expect(find.text('1× Helado'), findsOneWidget);

    await tester.tap(find.text('Pendientes').first);
    await tester.pumpAndSettle();
    expect(find.text('1× Crepes'), findsOneWidget);
    expect(find.text('1× Helado'), findsNothing);

    await tester.tap(find.text('Entregados').first);
    await tester.pumpAndSettle();
    expect(find.text('1× Crepes'), findsNothing);
    expect(find.text('1× Helado'), findsOneWidget);
  });

  group('reloading', () {
    testWidgets('re-activating the tab right away does not reload', (
      tester,
    ) async {
      _phoneView(tester);
      final service = _FakeMenuService();
      await tester.pumpWidget(_app(service, isActive: false));
      await tester.pumpAndSettle();
      expect(service.purchaseCalls, hasLength(1));

      await tester.pumpWidget(_app(service, isActive: true));
      await tester.pumpAndSettle();

      expect(service.purchaseCalls, hasLength(1));
    });

    testWidgets('a purchase signal reloads when the tab is shown', (
      tester,
    ) async {
      _phoneView(tester);
      final service = _FakeMenuService();
      await tester.pumpWidget(_app(service, isActive: false));
      await tester.pumpAndSettle();

      OrdersReloadSignal.request();
      await tester.pumpAndSettle();
      // Hidden tabs ask for nothing.
      expect(service.purchaseCalls, hasLength(1));

      await tester.pumpWidget(_app(service, isActive: true));
      await tester.pumpAndSettle();
      expect(service.purchaseCalls, hasLength(2));
    });

    testWidgets('a signal reloads at once when the tab is visible', (
      tester,
    ) async {
      _phoneView(tester);
      final service = _FakeMenuService();
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      OrdersReloadSignal.request();
      await tester.pumpAndSettle();

      expect(service.purchaseCalls, hasLength(2));
    });

    testWidgets('a hidden tab waits to load the new child until shown', (
      tester,
    ) async {
      _phoneView(tester);
      final provider = ChildrenProvider(authService: _FakeAuth());
      addTearDown(provider.dispose);
      await provider.refresh();
      final service = _FakeMenuService();
      await tester.pumpWidget(
        _app(service, isActive: false, provider: provider),
      );
      await tester.pumpAndSettle();
      expect(service.purchaseCalls, [5]);

      provider.select(6);
      await tester.pump();
      expect(service.purchaseCalls, [5]);

      await tester.pumpWidget(
        _app(service, isActive: true, provider: provider),
      );
      await tester.pumpAndSettle();
      expect(service.purchaseCalls, [5, 6]);
    });

    testWidgets('an old response never replaces a newer one', (tester) async {
      _phoneView(tester);
      final provider = ChildrenProvider(authService: _FakeAuth());
      addTearDown(provider.dispose);
      await provider.refresh();
      final service = _FakeMenuService();
      final pending = <int?, Completer<List<OrderEntry>>>{};
      service.purchases = (id) =>
          (pending[id] = Completer<List<OrderEntry>>()).future;

      await tester.pumpWidget(_app(service, provider: provider));
      await tester.pump();
      expect(service.purchaseCalls, [5]);

      provider.select(6);
      await tester.pump();
      expect(service.purchaseCalls, [5, 6]);

      // The newest answer arrives first; the old one arrives late.
      pending[6]!.complete([_order(2, studentId: 6, dish: 'Pan de Luis')]);
      await tester.pumpAndSettle();
      pending[5]!.complete([_order(1, studentId: 5, dish: 'Pan de Ana')]);
      await tester.pumpAndSettle();

      expect(find.text('1× Pan de Luis'), findsOneWidget);
      expect(find.text('1× Pan de Ana'), findsNothing);
    });
  });
}
