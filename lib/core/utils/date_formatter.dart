class DateFormatter {
  static const List<String> _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  static const List<String> _shortWeekdays = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  static const List<String> _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static const List<String> _shortMonths = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// Devuelve "miércoles"
  static String weekdayName(DateTime date) {
    return _weekdays[date.weekday - 1];
  }

  /// Devuelve "Mié"
  static String shortWeekdayName(DateTime date) {
    return _shortWeekdays[date.weekday - 1];
  }

  /// Devuelve "octubre"
  static String monthName(DateTime date) {
    return _months[date.month - 1];
  }

  /// Devuelve "oct"
  static String shortMonthName(DateTime date) {
    return _shortMonths[date.month - 1];
  }

  /// Devuelve formato largo: "miércoles 14 de octubre"
  static String formatLong(DateTime date) {
    return '${weekdayName(date)} ${date.day} de ${monthName(date)}';
  }

  /// Devuelve formato corto para chips: "Mié 14 oct"
  static String formatChip(DateTime date) {
    return '${shortWeekdayName(date)} ${date.day} ${shortMonthName(date)}';
  }

  /// Devuelve formato estándar de fecha: "14/10/2026"
  static String formatShort(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  /// Devuelve formato ISO "YYYY-MM-DD"
  static String toIsoDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  /// Parsea un string "YYYY-MM-DD" a DateTime local de forma segura
  static DateTime parseIsoDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? 2026;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return DateTime(y, m, d);
    }
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
