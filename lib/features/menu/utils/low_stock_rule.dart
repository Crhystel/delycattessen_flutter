/// Cuándo avisar que quedan pocas unidades. Un único lugar para productos y
/// combos, para que ambos avisen con el mismo umbral.
class LowStockRule {
  LowStockRule._();

  /// Con este número de unidades o menos se muestra "Quedan N".
  static const int threshold = 5;

  /// Quedan pocas unidades, pero no cero: sin stock el aviso es "Agotado".
  /// [stock] nulo (dato desconocido) nunca avisa.
  static bool isLow(int? stock) =>
      stock != null && stock > 0 && stock <= threshold;

  /// Queda una sola unidad.
  static bool isLast(int? stock) => stock == 1;
}
