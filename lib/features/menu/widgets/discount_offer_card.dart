import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/menu_models.dart';
import 'offer_card_frame.dart';
import 'offer_thumbnail.dart';

/// Discount in force: a row per product on offer with its photo, the previous
/// price crossed out and the new one. Prices come from the catalog
/// ([MenuItem.originalPrice] and [MenuItem.price], which is what the POS
/// charges), so they always match the sale.
class DiscountOfferCard extends StatelessWidget {
  final Promotion promotion;

  /// Catalog products by id.
  final Map<int, MenuItem> itemsById;

  /// Opens the detail of a product on offer, like any other product.
  final ValueChanged<MenuItem>? onProductTap;

  const DiscountOfferCard({
    super.key,
    required this.promotion,
    required this.itemsById,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final products = [for (final id in promotion.productIds) ?itemsById[id]];
    return OfferCardFrame(
      label: '-${promotion.discountPercentage}%',
      title: 'Descuento',
      endDate: promotion.endDate,
      imageUrl: promotion.imageUrl,
      child: products.isEmpty
          ? _buildNamesOnly(context)
          : Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _ProductPriceRow(
                    item: products[i],
                    onTap: onProductTap == null
                        ? null
                        : () => onProductTap!(products[i]),
                  ),
                ],
              ],
            ),
    );
  }

  /// Products that are not in the catalog (e.g. sold out): names only.
  Widget _buildNamesOnly(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        promotion.productNames.join(', '),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink900,
        ),
      ),
    );
  }
}

class _ProductPriceRow extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;

  const _ProductPriceRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final row = Row(
      children: [
        OfferThumbnail(imageUrl: item.imageUrl),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Stacked (previous above, new below) so the row stays narrow and the
        // name keeps its room with large fonts.
        // Capped to a share of the screen and scaled down if it still does not
        // fit (small phone + very large font), so the row never overflows.
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.3,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.hasDiscount)
                  Text(
                    '\$${item.originalPrice.toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink900.withValues(alpha: 0.45),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.brand700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right,
            color: AppColors.ink900.withValues(alpha: 0.5),
          ),
      ],
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
