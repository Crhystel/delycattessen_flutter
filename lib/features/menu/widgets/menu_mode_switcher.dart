import 'package:flutter/material.dart';

import '../../../core/widgets/segmented_switch.dart';

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

  @override
  Widget build(BuildContext context) {
    return SegmentedSwitch<MenuMode>(
      options: const [
        (MenuMode.monthly, 'Menú del mes'),
        (MenuMode.products, 'Productos'),
      ],
      selected: mode,
      onChanged: onChanged,
    );
  }
}
