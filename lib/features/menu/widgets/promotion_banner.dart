import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Banner of the offers in force above the product catalog: combos first,
/// then discounts. The uploaded image covers the whole card. One card fills
/// the width; with several, the next one peeks so the user knows they can
/// scroll. [onComboTap] (POS) makes the combo cards tappable.
class PromotionBanner extends StatelessWidget {
  static const double _height = 150;
  static const double _peekFactor = 0.85;

  final CatalogOffers offers;
  final ValueChanged<Combo>? onComboTap;

  const PromotionBanner({super.key, required this.offers, this.onComboTap});

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final combo in offers.combos)
        _OfferCard(
          imageUrl: combo.imageUrl,
          badge: '\$${combo.price.toStringAsFixed(2)}',
          crossedPrice: combo.regularPrice > combo.price
              ? '\$${combo.regularPrice.toStringAsFixed(2)}'
              : null,
          title: combo.name,
          endDate: combo.endDate,
          onTap: onComboTap == null ? null : () => onComboTap!(combo),
        ),
      for (final promotion in offers.promotions)
        _OfferCard(
          imageUrl: promotion.imageUrl,
          badge: '-${promotion.discountPercentage}%',
          title: promotion.productNames.join(', '),
          endDate: promotion.endDate,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth - AppSpacing.lg * 2;
            final cardWidth = cards.length == 1
                ? fullWidth
                : fullWidth * _peekFactor;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, index) =>
                  SizedBox(width: cardWidth, child: cards[index]),
            );
          },
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String? imageUrl;
  final String badge;
  final String? crossedPrice;
  final String title;
  final DateTime endDate;
  final VoidCallback? onTap;

  const _OfferCard({
    required this.imageUrl,
    required this.badge,
    required this.title,
    required this.endDate,
    this.crossedPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = imageUrl != null;
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: Material(
        color: AppColors.secondary500,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                LayoutBuilder(
                  builder: (context, constraints) => CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: AppImageCacheHelper.cacheSize(
                      context,
                      constraints.maxWidth,
                    ),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              // Darkens the bottom of the image so the text stays readable.
              if (hasImage)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.brand500,
                            borderRadius: AppRadius.fullAll,
                          ),
                          child: Text(
                            badge,
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (crossedPrice != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            crossedPrice!,
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (onTap != null)
                          const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hasta el ${DateFormatter.formatShort(endDate)}',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
