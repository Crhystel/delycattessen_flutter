import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/widgets/app_card.dart';

/// Insignia de la tarjeta (alérgeno, unidades en carrito, stock, etc.).
class CatalogBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const CatalogBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  const CatalogBadge.allergen({super.key})
    : label = 'Alérgeno',
      background = AppColors.dangerBg,
      foreground = AppColors.danger700,
      icon = Icons.warning_amber_rounded;

  const CatalogBadge.info(this.label, {super.key})
    : background = AppColors.secondary50,
      foreground = AppColors.secondary700,
      icon = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de producto (nombre, descripción, precio, imagen) usada por el
/// catálogo del padre y por el POS.
class CatalogItemCard extends StatelessWidget {
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final List<CatalogBadge> badges;

  /// Atenúa la tarjeta (p. ej. producto con alérgenos del usuario).
  final bool dimmed;
  final VoidCallback onTap;

  const CatalogItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.onTap,
    this.imageUrl,
    this.badges = const [],
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink900.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.brand700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      ...badges,
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildImage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: Container(
        width: 100,
        height: 75,
        color: AppColors.ink50,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: AppImageCacheHelper.cacheSize(context, 100),
                memCacheHeight: AppImageCacheHelper.cacheSize(context, 75),
                placeholder: (_, _) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary500,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.fastfood, color: AppColors.secondary500),
              )
            : const Icon(Icons.fastfood, color: AppColors.secondary500),
      ),
    );
  }
}
