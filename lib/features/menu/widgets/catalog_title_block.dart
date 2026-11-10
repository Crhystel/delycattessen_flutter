import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Title of the catalog and, below it, an optional [accessory] (e.g. the
/// "Menú del mes | Productos" selector). It is part of the block that
/// collapses when the list scrolls.
class CatalogTitleBlock extends StatelessWidget {
  final String title;

  /// Widget bajo el título (p. ej. el selector "Menú del mes | Productos").
  final Widget? accessory;

  const CatalogTitleBlock({super.key, required this.title, this.accessory});

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
