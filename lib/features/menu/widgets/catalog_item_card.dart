import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_network_image.dart';

/// Insignia de la tarjeta (alérgeno, unidades en carrito, stock, etc.).
class CatalogBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  /// Si se define, la insignia muestra una × para quitar el producto.
  final VoidCallback? onRemove;

  /// Píldora del rediseño del padre (radio total, texto 12/700). Por defecto la
  /// insignia es el rectángulo redondeado que usan docente y caja.
  final bool pill;

  const CatalogBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.onRemove,
    this.pill = false,
  });

  const CatalogBadge.allergen({super.key})
    : label = 'Alérgeno',
      background = AppColors.dangerBg,
      foreground = AppColors.danger700,
      icon = Icons.warning_amber_rounded,
      onRemove = null,
      pill = false;

  const CatalogBadge.discount(int percentage, {super.key})
    : label = '-$percentage%',
      background = AppColors.successBg,
      foreground = AppColors.success700,
      icon = Icons.local_offer_rounded,
      onRemove = null,
      pill = false;

  const CatalogBadge.info(this.label, {super.key, this.onRemove})
    : background = AppColors.secondary50,
      foreground = AppColors.secondary700,
      icon = null,
      pill = false;

  /// Esta misma insignia como píldora (filas de producto del padre).
  CatalogBadge asPill() => CatalogBadge(
    key: key,
    label: label,
    background: background,
    foreground: foreground,
    icon: icon,
    onRemove: onRemove,
    pill: true,
  );

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: pill ? 2 : 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(pill ? 999 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 3),
          ],
          // Flexible so a long label (or a large system font) is cut with an
          // ellipsis instead of overflowing the badge.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: pill
                  ? AppText.badge.copyWith(color: foreground)
                  : Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
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

  /// Price before a discount; shown crossed out next to [price].
  final double? originalPrice;
  final String? imageUrl;
  final List<CatalogBadge> badges;

  /// Atenúa la tarjeta (p. ej. producto con alérgenos del usuario).
  final bool dimmed;
  final VoidCallback onTap;

  /// Vista del padre: la foto va a la izquierda, las insignias bajo el nombre y
  /// el precio a la derecha. Por defecto (POS, docente) la foto va a la derecha.
  final bool leadingImage;

  const CatalogItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.onTap,
    this.originalPrice,
    this.imageUrl,
    this.badges = const [],
    this.dimmed = false,
    this.leadingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (leadingImage) return _buildLeadingImageCard(textTheme, context);
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
                            if (originalPrice != null)
                              Text(
                                '\$${originalPrice!.toStringAsFixed(2)}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.ink900.withValues(
                                    alpha: 0.45,
                                  ),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
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

  /// Fila del padre: foto, nombre, descripción, insignias y el precio a la
  /// derecha (con el anterior tachado si hay descuento).
  Widget _buildLeadingImageCard(TextTheme textTheme, BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildImageBox(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppText.itemTitle),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.secondary,
                          ),
                        ],
                        if (badges.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [for (final b in badges) b.asPill()],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (originalPrice != null)
                        Text(
                          '\$${originalPrice!.toStringAsFixed(2)}',
                          style: AppText.secondary.copyWith(
                            color: AppColors.placeholder,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: AppText.price.copyWith(
                          color: AppColors.brand700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _photoSize = 76;

  Widget _buildImageBox(BuildContext context) {
    return Container(
      width: _photoSize,
      height: _photoSize,
      color: AppColors.ink50,
      child: AppNetworkImage(
        url: imageUrl,
        width: _photoSize,
        height: _photoSize,
        error: const Icon(Icons.fastfood, color: AppColors.secondary500),
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
          width: _photoSize,
          height: _photoSize,
          color: AppColors.ink50,
          child: AppNetworkImage(
            url: imageUrl,
            width: _photoSize,
            height: _photoSize,
            placeholder: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary500,
                ),
              ),
            ),
            error: const Icon(Icons.fastfood, color: AppColors.secondary500),
          ),
        ),
      ),
    );
  }
}
