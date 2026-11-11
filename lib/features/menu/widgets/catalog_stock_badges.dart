import '../../../core/theme/app_colors.dart';
import '../utils/low_stock_rule.dart';
import 'catalog_item_card.dart';

/// Cómo se anuncian las unidades disponibles de un combo: la insignia para
/// [available] (nulo si no hay dato) o null si no hay nada que mostrar.
typedef StockBadgeBuilder = CatalogBadge? Function(int? available);

/// Insignias de stock de un combo (o de cualquier cantidad disponible). Cada
/// una devuelve null cuando no hay nada que avisar, para usarse tal cual en
/// una lista de insignias: `if (badge != null) badge`.
class CatalogStockBadges {
  CatalogStockBadges._();

  /// Consulta (padre, estudiante, docente): "Quedan N" con pocas unidades y
  /// "Última unidad" con una; con stock de sobra o desconocido, nada.
  static CatalogBadge? low(int? available) {
    if (!LowStockRule.isLow(available)) return null;
    if (LowStockRule.isLast(available)) {
      return const CatalogBadge(
        label: 'Última unidad',
        background: AppColors.dangerBg,
        foreground: AppColors.danger700,
      );
    }
    return CatalogBadge.info('Quedan $available');
  }

  /// Caja: la cantidad exacta, como en los productos ("Stock: N").
  static CatalogBadge? exact(int? available) =>
      available == null ? null : CatalogBadge.info('Stock: $available');

  /// Sin unidades que vender.
  static const CatalogBadge soldOut = CatalogBadge(
    label: 'Agotado',
    background: AppColors.dangerBg,
    foreground: AppColors.danger700,
  );
}
