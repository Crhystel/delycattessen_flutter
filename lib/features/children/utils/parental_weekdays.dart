/// Días de la semana del control parental. El índice es el del backend
/// (0 = lunes) y se muestra con su letra, su nombre completo y su forma corta.
class ParentalWeekday {
  final String letter;
  final String name;
  final String short;

  const ParentalWeekday(this.letter, this.name, this.short);

  static const List<ParentalWeekday> all = [
    ParentalWeekday('L', 'Lunes', 'Lun'),
    ParentalWeekday('M', 'Martes', 'Mar'),
    // Miércoles lleva "M" como en el diseño; el nombre lo distingue.
    ParentalWeekday('M', 'Miércoles', 'Mié'),
    ParentalWeekday('J', 'Jueves', 'Jue'),
    ParentalWeekday('V', 'Viernes', 'Vie'),
    ParentalWeekday('S', 'Sábado', 'Sáb'),
    ParentalWeekday('D', 'Domingo', 'Dom'),
  ];
}
