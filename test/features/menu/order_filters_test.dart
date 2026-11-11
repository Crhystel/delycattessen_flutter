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
  group('orderDay', () {
    test('a pre-order uses its delivery date, not when it was created', () {
      final order = _preorder(
        10,
        '2026-10-14',
        createdAt: DateTime(2026, 9, 1, 8),
      );

      expect(orderDay(order), DateTime(2026, 10, 14));
      expect(orderMonth(order), DateTime(2026, 10));
    });

    test('a point-of-sale purchase uses the day it was made', () {
      final purchase = _purchase(11, DateTime(2026, 10, 14, 13, 5));

      expect(orderDay(purchase), DateTime(2026, 10, 14));
    });
  });

  group('months', () {
    final orders = [
      _purchase(1, DateTime(2026, 10, 22, 21, 55)),
      _purchase(2, DateTime(2026, 10, 15, 22, 49)),
      _purchase(3, DateTime(2026, 9, 30, 9)),
      _purchase(4, DateTime(2025, 10, 14, 9)),
    ];

    test('monthsOf lists each month once, newest first', () {
      expect(monthsOf(orders), [
        DateTime(2026, 10),
        DateTime(2026, 9),
        DateTime(2025, 10),
      ]);
    });

    test('monthsOf of nothing is empty', () {
      expect(monthsOf(const []), isEmpty);
    });

    test('ordersInMonth matches month and year', () {
      expect(_ids(ordersInMonth(orders, DateTime(2026, 10))), [1, 2]);
      expect(_ids(ordersInMonth(orders, DateTime(2025, 10))), [4]);
      expect(ordersInMonth(orders, DateTime(2026, 8)), isEmpty);
    });
  });
}
