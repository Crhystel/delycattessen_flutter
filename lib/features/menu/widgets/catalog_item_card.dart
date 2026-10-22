import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';

/// Insignia de la tarjeta (alérgeno, unidades en carrito, stock, etc.).
class CatalogBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  /// Si se define, la insignia muestra una × para quitar el producto.
  final VoidCallback? onRemove;

  const CatalogBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.onRemove,
  });

  const CatalogBadge.allergen({super.key})
    : label = 'Alérgeno',
      background = AppColors.dangerBg,
      foreground = AppColors.danger700,
      icon = Icons.warning_amber_rounded,
      onRemove = null;

  const CatalogBadge.discount(int percentage, {super.key})
    : label = '-$percentage%',
      background = AppColors.successBg,
      foreground = AppColors.success700,
      icon = Icons.local_offer_rounded,
      onRemove = null;

  const CatalogBadge.info(this.label, {super.key, this.onRemove})
    : background = AppColors.secondary50,
      foreground = AppColors.secondary700,
      icon = null;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
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
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.close, size: 14, color: foreground),
          ],
        ],
      ),
    );
    if (onRemove == null) return badge;
    // Área táctil mínima de 40 px aunque la insignia sea pequeña.
    return Semantics(
      button: true,
      label: 'Quitar del carrito',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onRemove,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Center(widthFactor: 1, child: badge),
        ),
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
    // Tarjeta blanca con sombra suave, como las del menú en el Figma.
    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.ink900.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.smAll,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.ink900.withValues(alpha: 0.5),
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
                                color: AppColors.brand500,
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
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.smAll,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.smAll,
        child: Container(
          width: 76,
          height: 76,
          color: AppColors.ink50,
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: AppImageCacheHelper.cacheSize(context, 76),
                  memCacheHeight: AppImageCacheHelper.cacheSize(context, 76),
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
      ),
    );
  }
}
