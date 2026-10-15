import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum CategoryFilterStyle { circles, chips }

/// Filtro de categorías compartido. [selected] nulo = todas.
/// `circles`: burbujas con icono (vista del padre). `chips`: ChoiceChip (POS).
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
    return style == CategoryFilterStyle.chips
        ? _buildChips(options)
        : _buildCircles(context, options);
  }

  Widget _buildChips(List<String?> options) {
    return SizedBox(
      height: 48,
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
          height: 92,
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
                      width: 58,
                      height: 58,
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
                    const SizedBox(height: 6),
                    Text(
                      labelFor(category),
                      style: TextStyle(
                        fontSize: 13,
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
