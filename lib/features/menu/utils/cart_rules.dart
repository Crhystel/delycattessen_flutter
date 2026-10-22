/// Reglas compartidas de los carritos (platillos del padre y productos del POS).
/// Un carrito es un mapa `id -> cantidad`.
class CartRules {
  CartRules._();

  /// Con al menos este número de productos distintos se ofrece quitar uno
  /// completo, sin importar su cantidad.
  static const int minLinesForQuickRemove = 2;

  static bool canRemoveLine(int lineCount) =>
      lineCount >= minLinesForQuickRemove;

  /// Total del carrito. [priceOf] devuelve el precio unitario de un id, o
  /// null si ya no está disponible (esa línea no suma).
  static double total(Map<int, int> cart, double? Function(int id) priceOf) {
    var total = 0.0;
    for (final entry in cart.entries) {
      final price = priceOf(entry.key);
      if (price != null) total += price * entry.value;
    }
    return total;
  }

  /// Unidades totales en el carrito, sumando las cantidades de cada línea.
  static int itemCount(Map<int, int> cart) =>
      cart.values.fold(0, (sum, quantity) => sum + quantity);
}
