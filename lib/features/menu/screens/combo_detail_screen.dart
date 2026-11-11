import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';
import '../widgets/catalog_item_card.dart';
import '../widgets/catalog_stock_badges.dart';
import '../widgets/detail_chip.dart';
import '../widgets/detail_hero_image.dart';
import '../widgets/offer_thumbnail.dart';
import '../widgets/quantity_add_bar.dart';

/// Detail of a combo, laid out like the detail of a normal product: photo,
/// name and price (with the regular one crossed out), the dishes it includes
/// and their allergens. With [onAdd] (POS) it has the quantity bar; without it
/// (parents and teachers only consult the catalog) it is read-only. It shows
/// the units left and, sold out, "Agotado" with the add button disabled.
class ComboDetailScreen extends StatelessWidget {
  final Combo combo;

  /// Catalog products by id, for the photos, prices and allergens of the dishes.
  final Map<int, MenuItem> itemsById;

  /// Adds [quantity] combos to the cart; null in the consult-only catalogs.
  final ValueChanged<int>? onAdd;

  /// How the units left are announced; by default "Quedan N". The POS passes
  /// the exact stock.
  final StockBadgeBuilder stockBadge;

  const ComboDetailScreen({
    super.key,
    required this.combo,
    required this.itemsById,
    this.onAdd,
    this.stockBadge = CatalogStockBadges.low,
  });

  /// Photo of the combo, or the one of its first dish when it has none.
  String? get _imageUrl {
    if (combo.imageUrl != null) return combo.imageUrl;
    for (final dish in combo.items) {
      final url = itemsById[dish.productId]?.imageUrl;
      if (url != null) return url;
    }
    return null;
  }

  /// Allergens of every dish of the combo, without repeats.
  List<String> get _allergenNames {
    final names = <String>{};
    for (final dish in combo.items) {
      final allergens = itemsById[dish.productId]?.allergens;
      if (allergens == null) continue;
      for (final allergen in allergens) {
        names.add(allergen.name);
      }
    }
    return names.toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final add = onAdd;
    final allergens = _allergenNames;
    final stock = stockBadge(combo.availableQuantity);

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailHeroImage(imageUrl: _imageUrl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      combo.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // The prices go under the name (not beside it) so a long
                    // name or a large system font never pushes them out.
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '\$${combo.price.toStringAsFixed(2)}',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand700,
                          ),
                        ),
                        if (combo.hasSavings)
                          Text(
                            '\$${combo.regularPrice.toStringAsFixed(2)}',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.ink900.withValues(alpha: 0.45),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const CatalogBadge.info('Combo'),
                        if (!combo.isAvailable)
                          CatalogStockBadges.soldOut
                        else
                          ?stock,
                        if (combo.hasSavings)
                          CatalogBadge(
                            label:
                                'Ahorras \$${combo.savings.toStringAsFixed(2)}',
                            background: AppColors.successBg,
                            foreground: AppColors.success700,
                            icon: Icons.local_offer_rounded,
                          ),
                        Text(
                          'Válido hasta el ${DateFormatter.formatShort(combo.endDate)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.ink900.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _SectionTitle('Incluye'),
                    for (final dish in combo.items) ...[
                      _DishRow(dish: dish, item: itemsById[dish.productId]),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (allergens.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      const _SectionTitle('Contiene alérgenos'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final name in allergens)
                            DetailChip(name, isAllergen: true),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (add != null)
              QuantityAddBar(
                unitPrice: combo.price,
                onAdd: add,
                maxQuantity: combo.availableQuantity,
              ),
          ],
        ),
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  final ComboItem dish;
  final MenuItem? item;

  const _DishRow({required this.dish, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final price = item?.price;
    return Row(
      children: [
        OfferThumbnail(imageUrl: item?.imageUrl, size: 56),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dish.quantity > 1
                    ? '${dish.name} ×${dish.quantity}'
                    : dish.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              if (price != null)
                Text(
                  '\$${price.toStringAsFixed(2)} c/u',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ],
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
