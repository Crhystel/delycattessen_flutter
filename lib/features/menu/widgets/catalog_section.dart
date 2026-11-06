import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Recuadro con borde que agrupa los productos bajo el nombre de la
/// categoría elegida (Figma: "General", "Snacks", "Bebidas"...). Es un sliver:
/// el recuadro y su título se desplazan junto con las tarjetas, dentro del
/// mismo `CustomScrollView` que la cabecera que se encoge.
class CatalogSectionSliver extends StatelessWidget {
  final String title;

  /// Contenido del recuadro: ofertas, tarjetas o el estado vacío (slivers).
  final List<Widget> slivers;

  const CatalogSectionSliver({
    super.key,
    required this.title,
    required this.slivers,
  });

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: AppColors.ink900.withValues(alpha: 0.12)),
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ),
            ...slivers,
          ],
        ),
      ),
    );
  }
}
