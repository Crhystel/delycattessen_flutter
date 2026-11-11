import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// `circles`: burbujas con título "Categorías" que se desplazan (docente).
/// `evenCircles`: burbujas sin título que se reparten el ancho (padre).
/// `chips`: ChoiceChip (POS).
enum CategoryFilterStyle { circles, evenCircles, chips }

/// Filtro de categorías compartido. [selected] nulo = todas.
class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final CategoryFilterStyle style;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.style = CategoryFilterStyle.circles,
  });

  static const double _circleSize = 58;
  static const double _evenCircleSize = 56;
  static const double _evenItemWidth = 76;
  static const int _evenColumns = 4;
  static const String evenAllLabel = 'Todo';
  static const double _circleLabelGap = 6;
  static const double _circleLabelFont = 13;
  static const double _circlesMinHeight = 92;

  static const Map<String, IconData> _icons = {
    'bar': Icons.local_bar,
    'almuerzo': Icons.restaurant_menu,
    'snacks': Icons.lunch_dining,
    'bebidas': Icons.local_drink,
    'postres': Icons.icecream,
  };

  static IconData iconFor(String category) =>
      _icons[category.toLowerCase()] ?? Icons.restaurant;

  /// Nombre de la opción que muestra todos los productos (Figma: "General").
  static const String allLabel = 'General';

  /// Título a mostrar para la categoría elegida (null = todas).
  static String labelFor(String? category) => category ?? allLabel;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final options = <String?>[null, ...categories];
    return switch (style) {
      CategoryFilterStyle.chips => _buildChips(context, options),
      CategoryFilterStyle.evenCircles => _buildEvenCircles(context, options),
      CategoryFilterStyle.circles => _buildCircles(context, options),
    };
  }

  Widget _buildChips(BuildContext context, List<String?> options) {
    return SizedBox(
      height: math.max(
        48,
        MediaQuery.textScalerOf(context).scale(32) + 2 * AppSpacing.sm,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final category = options[index];
          return ChoiceChip(
            label: Text(labelFor(category)),
            selected: category == selected,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }

  /// Burbujas del padre: hasta 4 se reparten el ancho en columnas iguales;
  /// con más, se desplazan de lado a lado.
  Widget _buildEvenCircles(BuildContext context, List<String?> options) {
    Widget item(String? category) => _EvenCircle(
      label: category ?? evenAllLabel,
      icon: category == null ? Icons.storefront_outlined : iconFor(category),
      selected: selected == category,
      onTap: () => onSelected(category),
    );
    if (options.length <= _evenColumns) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final category in options) Expanded(child: item(category)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in options)
            SizedBox(width: _evenItemWidth, child: item(category)),
        ],
      ),
    );
  }

  Widget _buildCircles(BuildContext context, List<String?> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Categorías',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          // The label grows with the system font size: the row grows with it.
          height: math.max(
            _circlesMinHeight,
            _circleSize +
                _circleLabelGap +
                MediaQuery.textScalerOf(context).scale(_circleLabelFont) * 1.5,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (_, index) {
              final category = options[index];
              final isSelected = selected == category;
              return GestureDetector(
                onTap: () => onSelected(category),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Círculo morado del Figma: relleno al estar elegido,
                    // morado claro con borde cuando no.
                    Container(
                      width: _circleSize,
                      height: _circleSize,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary500
                            : AppColors.secondary50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary500.withValues(
                            alpha: isSelected ? 1 : 0.35,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        category == null
                            ? Icons.storefront_outlined
                            : iconFor(category),
                        color: isSelected
                            ? Colors.white
                            : AppColors.secondary500,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: _circleLabelGap),
                    Text(
                      labelFor(category),
                      style: TextStyle(
                        fontSize: _circleLabelFont,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.ink900
                            : AppColors.ink900.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Burbuja de categoría del padre: morada llena si está elegida, blanca con
/// borde morado si no; la etiqueta se adapta a la letra del sistema.
class _EvenCircle extends StatelessWidget {
  const _EvenCircle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: CategoryFilterBar._evenCircleSize,
              height: CategoryFilterBar._evenCircleSize,
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary500 : Colors.white,
                shape: BoxShape.circle,
                border: selected
                    ? null
                    : Border.all(color: AppColors.secondary500, width: 1.5),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : AppColors.secondary500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.ink900 : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
