import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Periodo por el que se filtran los pedidos.
enum OrderDateRange {
  all('Todos'),
  today('Hoy'),
  week('Esta semana'),
  month('Este mes');

  final String label;
  const OrderDateRange(this.label);
}

/// Día al que pertenece un pedido: el de entrega si es una preorden (así
/// "Hoy" muestra lo que se retira hoy) y el de la compra si fue en caja.
DateTime orderDay(OrderEntry order) {
  final date = order.deliveryDate.isNotEmpty
      ? DateFormatter.parseIsoDate(order.deliveryDate)
      : order.createdAt.toLocal();
  return DateTime(date.year, date.month, date.day);
}

/// Pedidos que caen dentro de [range]. La semana va de lunes a domingo.
/// [now] solo se pasa en pruebas.
List<OrderEntry> filterOrdersByRange(
  List<OrderEntry> orders,
  OrderDateRange range, {
  DateTime? now,
}) {
  if (range == OrderDateRange.all) return orders;

  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final nextWeekStart = weekStart.add(const Duration(days: 7));

  bool matches(DateTime day) => switch (range) {
    OrderDateRange.all => true,
    OrderDateRange.today => day == today,
    OrderDateRange.week =>
      !day.isBefore(weekStart) && day.isBefore(nextWeekStart),
    OrderDateRange.month => day.year == today.year && day.month == today.month,
  };

  return orders.where((order) => matches(orderDay(order))).toList();
}
