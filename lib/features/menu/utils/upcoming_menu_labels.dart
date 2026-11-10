import '../../../core/utils/date_formatter.dart';

/// Textos de la sección "Mañana en el menú" de Inicio. Reglas puras (reciben
/// "hoy" como parámetro) para poder probarlas sin reloj.
class UpcomingMenuLabels {
  UpcomingMenuLabels._();

  /// True si [date] es el día siguiente a [now] (se comparan solo año, mes y día).
  static bool isTomorrow(DateTime date, DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// "Mañana en el menú" si el primer día con platillos es mañana; si no,
  /// "Próximo menú".
  static String sectionTitle(DateTime date, DateTime now) =>
      isTomorrow(date, now) ? 'Mañana en el menú' : 'Próximo menú';

  /// Línea de fecha de la tarjeta: "Martes 10" cuando es mañana (el contexto ya
  /// lo dice el título); si no, la fecha completa: "Viernes 13 de noviembre".
  /// El backend aún no envía la hora límite de pedido, así que no se muestra.
  static String dateLine(DateTime date, DateTime now) {
    if (!isTomorrow(date, now)) {
      return DateFormatter.formatLongCapitalized(date);
    }
    final weekday = DateFormatter.weekdayName(date);
    return '${weekday[0].toUpperCase()}${weekday.substring(1)} ${date.day}';
  }
}
