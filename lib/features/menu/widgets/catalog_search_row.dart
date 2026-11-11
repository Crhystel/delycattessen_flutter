import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'catalog_search_field.dart';

/// Fixed top row of the catalogs (parent, teacher and POS): the back arrow
/// (when there is one) and the search field. It stays visible while the rest
/// of the header collapses on scroll.
class CatalogSearchRow extends StatelessWidget {
  final bool showBackButton;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  /// Texto del campo y estilo del rediseño del padre (ver [CatalogSearchField]).
  final String hintText;
  final bool outlined;

  /// Márgenes del rediseño del padre (20 a los lados, 14 sobre el campo).
  final bool design;

  const CatalogSearchRow({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.showBackButton = false,
    this.hintText = 'Buscar...',
    this.outlined = false,
    this.design = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: design
          ? EdgeInsets.fromLTRB(
              showBackButton ? AppSpacing.xs : AppSpacing.page,
              14,
              AppSpacing.page,
              0,
            )
          : EdgeInsets.fromLTRB(
              showBackButton ? AppSpacing.xs : AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
      child: Row(
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
              hintText: hintText,
              outlined: outlined,
            ),
          ),
        ],
      ),
    );
  }
}
