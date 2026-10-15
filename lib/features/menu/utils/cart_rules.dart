/// Reglas compartidas de los carritos (platillos del padre y productos del POS).
class CartRules {
  CartRules._();

  /// Con al menos este número de productos distintos se ofrece quitar uno
  /// completo, sin importar su cantidad.
  static const int minLinesForQuickRemove = 2;

  static bool canRemoveLine(int lineCount) =>
      lineCount >= minLinesForQuickRemove;
}
