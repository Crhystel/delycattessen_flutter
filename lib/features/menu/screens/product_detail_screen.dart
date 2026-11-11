import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/menu_models.dart';
import '../widgets/detail_chip.dart';
import '../widgets/detail_hero_image.dart';
import '../widgets/quantity_add_bar.dart';

class ProductDetailScreen extends StatelessWidget {
  final MenuItem item;

  /// Si es nulo la pantalla es de solo consulta (sin cantidad ni botón añadir).
  final ValueChanged<int>? onAdd;

  const ProductDetailScreen({super.key, required this.item, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final add = onAdd;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailHeroImage(imageUrl: item.imageUrl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Price under the name (not beside it) so a long name or
                    // a large system font never pushes it out of the screen.
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand700,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        item.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink900.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                    if (item.ingredients.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionTitle('Ingredientes'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final i in item.ingredients) DetailChip(i.name),
                        ],
                      ),
                    ],
                    if (item.allergens.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionTitle('Contiene alérgenos'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final a in item.allergens)
                            DetailChip(a.name, isAllergen: true),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (add != null) QuantityAddBar(unitPrice: item.price, onAdd: add),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
