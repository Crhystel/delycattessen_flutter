import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/menu_models.dart';
import 'catalog_item_card.dart';
import 'offer_card_frame.dart';
import 'offer_thumbnail.dart';

/// Combo in force: the dishes it includes (photo, name and quantity), the
/// fixed price with the regular one crossed out and what the customer saves.
/// With [onAdd] (POS) it has an "Agregar combo" button that adds the whole
/// combo as one line; without it (parents and teachers only consult the
/// catalog) it points to the counter.
class ComboOfferCard extends StatelessWidget {
  final Combo combo;

  /// Catalog products by id, to show each dish's photo.
  final Map<int, MenuItem> itemsById;

  /// Adds the combo to the cart; null in the consult-only catalogs.
  final VoidCallback? onAdd;

  /// Units of this combo already in the cart (POS).
  final int inCart;

  /// A dish contains an allergen of the customer (POS).
  final bool blocked;

  /// Opens the detail of the combo, like tapping a normal product.
  final VoidCallback? onTap;

  const ComboOfferCard({
    super.key,
    required this.combo,
    required this.itemsById,
    this.onAdd,
    this.inCart = 0,
    this.blocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: blocked ? 0.75 : 1.0,
      child: OfferCardFrame(
        label: 'COMBO',
        title: combo.name,
        endDate: combo.endDate,
        imageUrl: combo.imageUrl,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDishes(context),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '\$${combo.price.toStringAsFixed(2)}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.brand700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (combo.hasSavings) ...[
                  Text(
                    '\$${combo.regularPrice.toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink900.withValues(alpha: 0.45),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  CatalogBadge(
                    label: 'Ahorras \$${combo.savings.toStringAsFixed(2)}',
                    background: AppColors.successBg,
                    foreground: AppColors.success700,
                    icon: Icons.local_offer_rounded,
                  ),
                ],
                if (blocked) const CatalogBadge.allergen(),
                if (inCart > 0) CatalogBadge.info('$inCart en carrito'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDishes(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tiles = <Widget>[];
    for (var i = 0; i < combo.items.length; i++) {
      final dish = combo.items[i];
      if (i > 0) {
        tiles.add(
          Icon(
            Icons.add,
            size: 18,
            color: AppColors.ink900.withValues(alpha: 0.5),
          ),
        );
      }
      tiles.add(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OfferThumbnail(imageUrl: itemsById[dish.productId]?.imageUrl),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  dish.quantity > 1
                      ? '${dish.name} ×${dish.quantity}'
                      : dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: tiles,
    );
  }

  Widget _buildAction(BuildContext context) {
    final add = onAdd;
    if (add == null) {
      return Row(
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 18,
            color: AppColors.ink900.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Cómpralo en caja',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    return ElevatedButton.icon(
      onPressed: add,
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
      label: const Text(
        'Agregar combo',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand500,
        foregroundColor: AppColors.ink900,
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        elevation: 0,
      ),
    );
  }
}
