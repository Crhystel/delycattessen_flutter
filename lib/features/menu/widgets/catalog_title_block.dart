import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/tab_header.dart';

/// Title of the catalog and, below it, an optional [accessory] (e.g. the
/// "Menú del mes | Productos" selector). It is part of the block that
/// collapses when the list scrolls. [trailing] sits at the right of the title
/// (the parent's profile bubble).
class CatalogTitleBlock extends StatelessWidget {
  final String title;

  /// Widget bajo el título (p. ej. el selector "Menú del mes | Productos").
  final Widget? accessory;

  /// Widget a la derecha del título (p. ej. la burbuja de perfil del padre).
  final Widget? trailing;

  /// Cabecera del rediseño del padre: título de pestaña 30/800, márgenes de 20
  /// y 16 entre el título y el selector. El margen de la barra de estado lo pone
  /// quien aloja la cabecera (`CollapsingHeader.topInset`).
  final bool design;

  const CatalogTitleBlock({
    super.key,
    required this.title,
    this.accessory,
    this.trailing,
    this.design = false,
  });

  @override
  Widget build(BuildContext context) {
    if (design) return _buildDesign();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
          ),
          if (accessory != null) ...[
            const SizedBox(height: AppSpacing.sm),
            accessory!,
          ],
        ],
      ),
    );
  }

  /// Misma cabecera que Inicio y Pedidos ([TabHeader]): la burbuja queda anclada
  /// arriba. El margen de la barra de estado ya lo suma `CollapsingHeader`, así
  /// que aquí solo va el margen fijo de 16.
  Widget _buildDesign() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabHeader(
          topPadding: AppSpacing.lg,
          leading: Text(title, style: AppText.tabTitle),
          trailing: trailing,
        ),
        if (accessory != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: accessory!,
          ),
        ],
      ],
    );
  }
}
