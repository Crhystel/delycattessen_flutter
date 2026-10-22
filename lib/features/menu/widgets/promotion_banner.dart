import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/menu_models.dart';

/// Banner of the promotions in force (HU-03.3) above the product catalog.
/// The uploaded image covers the whole card. One promotion fills the width;
/// with several, the next card peeks so the user knows they can scroll.
class PromotionBanner extends StatelessWidget {
  static const double _height = 150;
  static const double _peekFactor = 0.85;

  final List<Promotion> promotions;

  const PromotionBanner({super.key, required this.promotions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth - AppSpacing.lg * 2;
            final cardWidth = promotions.length == 1
                ? fullWidth
                : fullWidth * _peekFactor;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: promotions.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, index) => SizedBox(
                width: cardWidth,
                child: _PromotionCard(
                  promotion: promotions[index],
                  width: cardWidth,
                  height: _height,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final Promotion promotion;
  final double width;
  final double height;

  const _PromotionCard({
    required this.promotion,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = promotion.imageUrl != null;
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.secondary500),
          if (hasImage)
            CachedNetworkImage(
              imageUrl: promotion.imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: AppImageCacheHelper.cacheSize(context, width),
              memCacheHeight: AppImageCacheHelper.cacheSize(context, height),
              errorWidget: (_, _, _) => const SizedBox.shrink(),
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
                    '-${promotion.discountPercentage}%',
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  promotion.productNames.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hasta el ${DateFormatter.formatShort(promotion.endDate)}',
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
    );
  }
}
