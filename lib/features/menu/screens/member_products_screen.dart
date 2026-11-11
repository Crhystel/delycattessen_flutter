import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../services/product_catalog_source.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_catalog_view.dart';

/// Catálogo de productos de solo consulta para estudiantes y docentes: de dónde
/// salen los productos y las alergias lo decide la [source] que recibe. Usa el
/// mismo diseño que el del padre (combos en carrusel, descuentos y filas con
/// foto); al no recibir `onAdd` no hay botón para agregar.
class MemberProductsScreen extends StatelessWidget {
  const MemberProductsScreen({super.key, required this.source});

  /// Una sola instancia mientras la pantalla vive: la vista recarga solo
  /// cuando cambia el `id` de la fuente.
  final ProductCatalogSource source;

  @override
  Widget build(BuildContext context) {
    return ProductCatalogView(
      source: source,
      title: 'Productos',
      showBackButton: true,
      categoryStyle: CategoryFilterStyle.evenCircles,
      backgroundColor: AppColors.ink50,
      flatLayout: true,
    );
  }
}
