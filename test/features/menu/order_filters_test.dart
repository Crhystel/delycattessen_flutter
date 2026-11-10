import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/utils/order_filters.dart';
import 'package:flutter_test/flutter_test.dart';

OrderEntry _preorder(int id, String deliveryDate, {DateTime? createdAt}) =>
    OrderEntry(
      id: id,
      studentName: 'Ana',
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      status: PreOrderStatus.pending,
      statusDisplay: 'Pendiente',
      deliveryDate: deliveryDate,
      totalAmount: 1,
      items: const [],
      origin: OrderOrigin.preorder,
    );

OrderEntry _purchase(int id, DateTime createdAt) => OrderEntry(
  id: id,
  studentName: 'Ana',
  createdAt: createdAt,
  status: PreOrderStatus.delivered,
  statusDisplay: 'Entregado',
  deliveryDate: '',
  totalAmount: 1,
  items: const [],
  origin: OrderOrigin.pointOfSale,
);

List<int> _ids(List<OrderEntry> orders) => [for (final o in orders) o.id];

void main() {
  // Miércoles 14 de octubre de 2026: la semana va del lunes 12 al domingo 18.
  final now = DateTime(2026, 10, 14, 10);

  final today = _preorder(1, '2026-10-14');
  final mondayOfWeek = _preorder(2, '2026-10-12');
  final sundayOfWeek = _preorder(3, '2026-10-18');
  final previousSunday = _preorder(4, '2026-10-11');
  final nextMonday = _preorder(5, '2026-10-19');
  final laterThisMonth = _preorder(6, '2026-10-30');
  final lastMonth = _preorder(7, '2026-09-30');
  final sameMonthLastYear = _preorder(8, '2025-10-14');
  final all = [
    today,
    mondayOfWeek,
    sundayOfWeek,
    previousSunday,
    nextMonday,
    laterThisMonth,
    lastMonth,
    sameMonthLastYear,
  ];

  group('filterOrdersByRange', () {
    test('all keeps every order', () {
      expect(filterOrdersByRange(all, OrderDateRange.all, now: now), all);
    });

    test('today keeps only the current day', () {
      expect(_ids(filterOrdersByRange(all, OrderDateRange.today, now: now)), [
        1,
      ]);
    });

    test('week goes from Monday to Sunday', () {
      expect(_ids(filterOrdersByRange(all, OrderDateRange.week, now: now)), [
        1,
        2,
        3,
      ]);
    });

    test('week also works when today is Sunday', () {
      final sunday = DateTime(2026, 10, 18, 23, 30);

      expect(_ids(filterOrdersByRange(all, OrderDateRange.week, now: sunday)), [
        1,
        2,
        3,
      ]);
    });

    test('month matches month and year', () {
      expect(_ids(filterOrdersByRange(all, OrderDateRange.month, now: now)), [
        1,
        2,
        3,
        4,
        5,
        6,
      ]);
    });
  });

  group('orderDay', () {
    test('a pre-order uses its delivery date, not when it was created', () {
      final order = _preorder(
        10,
        '2026-10-14',
        createdAt: DateTime(2026, 9, 1, 8),
      );

      expect(orderDay(order), DateTime(2026, 10, 14));
      expect(
        _ids(filterOrdersByRange([order], OrderDateRange.today, now: now)),
        [10],
      );
    });

    test('a point-of-sale purchase uses the day it was made', () {
      final purchase = _purchase(11, DateTime(2026, 10, 14, 13, 5));

      expect(orderDay(purchase), DateTime(2026, 10, 14));
      expect(
        _ids(filterOrdersByRange([purchase], OrderDateRange.today, now: now)),
        [11],
      );
      expect(
        filterOrdersByRange(
          [purchase],
          OrderDateRange.today,
          now: DateTime(2026, 10, 15),
        ),
        isEmpty,
      );
    });
  });
}
