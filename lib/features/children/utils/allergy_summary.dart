import '../../users/models/allergy_models.dart';

/// Texto de una línea con las alergias del hijo para las filas de resumen.
class AllergySummary {
  AllergySummary._();

  /// Mientras las alergias cargan (o no están disponibles).
  static const String placeholder = 'Toca para ver o editar';

  static const String none = 'Sin alergias registradas';

  /// "Sulfitos, Sésamo", [none] si no hay, o [placeholder] si aún no se cargan.
  static String of(List<Allergen>? allergies) {
    if (allergies == null) return placeholder;
    if (allergies.isEmpty) return none;
    return allergies.map((a) => a.name).join(', ');
  }
}
