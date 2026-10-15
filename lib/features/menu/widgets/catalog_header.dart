import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'catalog_search_field.dart';

/// Encabezado del catálogo según el Figma: flecha y buscador en la misma
/// fila, y debajo el título. Compartido por el catálogo del padre, el del
/// docente y el del POS.
class CatalogHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  /// Widget bajo el título (p. ej. el selector "Menú del mes | Productos").
  final Widget? accessory;

  const CatalogHeader({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearchChanged,
    this.showBackButton = false,
    this.accessory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        showBackButton ? AppSpacing.xs : AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: AppColors.ink900,
                  tooltip: 'Volver',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              Expanded(
                child: CatalogSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: EdgeInsets.only(
              left: showBackButton ? AppSpacing.md : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                if (accessory != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  accessory!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
