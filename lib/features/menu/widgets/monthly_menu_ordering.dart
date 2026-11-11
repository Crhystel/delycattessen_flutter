import '../models/menu_models.dart';

/// Acciones de pedido del menú del mes. Quien aloja la vista las inyecta; sin
/// ellas ([MonthlyMenuView.ordering] nulo) la vista es de solo lectura.
class MonthlyMenuOrdering {
  const MonthlyMenuOrdering({
    required this.onToggleDish,
    required this.onAddDish,
  });

  /// Botón "Agregar / Agregado" de la tarjeta: agrega o quita 1 unidad.
  final void Function(MenuDish dish) onToggleDish;

  /// "Añadir" del detalle del platillo, con la cantidad elegida.
  final void Function(MenuDish dish, int quantity) onAddDish;
}
