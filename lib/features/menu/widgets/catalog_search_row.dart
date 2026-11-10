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

  const CatalogSearchRow({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.showBackButton = false,
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
            ),
          ),
        ],
      ),
    );
  }
}
