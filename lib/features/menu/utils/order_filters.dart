import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Estado por el que se filtran los pedidos en la pestaña Pedidos.
enum OrderStatusFilter {
  all('Todos'),
  pending('Pendientes'),
  delivered('Entregados');

  final String label;
  const OrderStatusFilter(this.label);
}

/// Pedidos que coinciden con [filter]: "Pendientes" son las preórdenes por
/// retirar y "Entregados" todo lo demás (entregado o cancelado).
List<OrderEntry> filterOrdersByStatus(
  List<OrderEntry> orders,
  OrderStatusFilter filter,
) => switch (filter) {
  OrderStatusFilter.all => orders,
  OrderStatusFilter.pending => orders.where((o) => o.isPendingPickup).toList(),
  OrderStatusFilter.delivered =>
    orders.where((o) => !o.isPendingPickup).toList(),
};

/// Día al que pertenece un pedido: el de entrega si es una preorden y el de la
/// compra si fue en caja.
DateTime orderDay(OrderEntry order) {
  final date = order.deliveryDate.isNotEmpty
      ? DateFormatter.parseIsoDate(order.deliveryDate)
      : order.createdAt.toLocal();
  return DateTime(date.year, date.month, date.day);
}

/// Primer día del mes al que pertenece un pedido (ver [orderDay]).
DateTime orderMonth(OrderEntry order) {
  final day = orderDay(order);
  return DateTime(day.year, day.month);
}

/// Meses que tienen pedidos, del más reciente al más antiguo y sin repetir.
List<DateTime> monthsOf(List<OrderEntry> orders) {
  final months = {for (final order in orders) orderMonth(order)}.toList()
    ..sort((a, b) => b.compareTo(a));
  return months;
}

/// Pedidos que caen en [month] (cualquier día de ese mes y año).
List<OrderEntry> ordersInMonth(List<OrderEntry> orders, DateTime month) =>
    orders
        .where((o) => orderMonth(o) == DateTime(month.year, month.month))
        .toList();
