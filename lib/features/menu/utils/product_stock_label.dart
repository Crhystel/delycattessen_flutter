import 'low_stock_rule.dart';

/// Text of the "Disponibles hoy" tile of a product. Consult-only catalogs say
/// "Quedan N" when few are left and "Disponible" otherwise; the POS, with
/// [exact], shows the real count.
String productStockLabel(int stock, {bool exact = false}) {
  if (stock <= 0) return 'Agotado';
  if (exact) return stock == 1 ? '1 unidad' : '$stock unidades';
  return LowStockRule.isLow(stock) ? 'Quedan $stock' : 'Disponible';
}
