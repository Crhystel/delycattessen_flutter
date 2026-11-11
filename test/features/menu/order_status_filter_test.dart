import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/utils/order_filters.dart';
import 'package:flutter_test/flutter_test.dart';

OrderEntry _order(
  int id, {
  required OrderOrigin origin,
  required PreOrderStatus status,
}) => OrderEntry(
  id: id,
  studentName: 'Ana Mora',
  createdAt: DateTime(2026, 11, 9, 10),
  status: status,
  statusDisplay: status.name,
  deliveryDate: origin == OrderOrigin.preorder ? '2026-11-10' : '',
  totalAmount: 3.5,
  items: const [],
  origin: origin,
);

void main() {
  final pending = _order(
    1,
    origin: OrderOrigin.preorder,
    status: PreOrderStatus.pending,
  );
  final delivered = _order(
    2,
    origin: OrderOrigin.preorder,
    status: PreOrderStatus.delivered,
  );
  final inStore = _order(
    3,
    origin: OrderOrigin.pointOfSale,
    status: PreOrderStatus.delivered,
  );
  final canceled = _order(
    4,
    origin: OrderOrigin.preorder,
    status: PreOrderStatus.canceled,
  );
  final all = [pending, delivered, inStore, canceled];

  test('"Todos" keeps every order', () {
    expect(filterOrdersByStatus(all, OrderStatusFilter.all), all);
  });

  test('"Pendientes" are only the pre-orders waiting to be picked up', () {
    expect(filterOrdersByStatus(all, OrderStatusFilter.pending), [pending]);
  });

  test('"Entregados" is everything that is no longer pending', () {
    expect(filterOrdersByStatus(all, OrderStatusFilter.delivered), [
      delivered,
      inStore,
      canceled,
    ]);
  });
}
