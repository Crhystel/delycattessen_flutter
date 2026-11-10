import 'package:flutter/material.dart';

import '../widgets/menu_mode_switcher.dart';
import 'menu_screen.dart';
import 'parent_products_screen.dart';

/// Pestaña "Menú" del padre: alterna entre el menú mensual y el catálogo de
/// productos. Ambas vistas conservan su estado al alternar y el catálogo se
/// construye (y carga) solo la primera vez que se abre.
class ParentMenuTab extends StatefulWidget {
  final DateTime? initialDate;

  const ParentMenuTab({super.key, this.initialDate});

  @override
  State<ParentMenuTab> createState() => _ParentMenuTabState();
}

class _ParentMenuTabState extends State<ParentMenuTab> {
  MenuMode _mode = MenuMode.monthly;
  bool _productsVisited = false;

  void _setMode(MenuMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      if (mode == MenuMode.products) _productsVisited = true;
    });
  }

  Widget get _switcher => MenuModeSwitcher(mode: _mode, onChanged: _setMode);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _mode.index,
      children: [
        MenuScreen(
          embedded: true,
          initialDate: widget.initialDate,
          headerAccessory: _switcher,
        ),
        if (_productsVisited)
          ParentProductsScreen(headerAccessory: _switcher)
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
