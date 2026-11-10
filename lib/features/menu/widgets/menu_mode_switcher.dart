import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum MenuMode { monthly, products }

/// Selector "Menú del mes | Productos" de la pestaña Menú del padre.
class MenuModeSwitcher extends StatelessWidget {
  final MenuMode mode;
  final ValueChanged<MenuMode> onChanged;

  const MenuModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  static const Map<MenuMode, String> _labels = {
    MenuMode.monthly: 'Menú del mes',
    MenuMode.products: 'Productos',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in _labels.entries) ...[
          ChoiceChip(
            label: Text(entry.value),
            selected: mode == entry.key,
            showCheckmark: false,
            selectedColor: AppColors.secondary500,
            backgroundColor: AppColors.secondary50,
            side: BorderSide.none,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: mode == entry.key ? Colors.white : AppColors.secondary700,
            ),
            onSelected: (_) => onChanged(entry.key),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}
