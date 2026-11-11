import 'package:flutter/material.dart';

import '../widgets/menu_mode_switcher.dart';
import 'menu_screen.dart';
import 'parent_products_screen.dart';

/// Pestaña "Menú" del padre: alterna entre el menú mensual y el catálogo de
/// productos. Ambas vistas conservan su estado al alternar y el catálogo se
/// construye (y carga) solo la primera vez que se abre.
class ParentMenuTab extends StatefulWidget {
  final DateTime? initialDate;

  /// Vista con la que abre la pestaña (Inicio puede pedir "Productos").
  final MenuMode initialMode;

  /// Cambia cada vez que Inicio pide un día o "Productos". La pestaña lo
  /// atiende sin recrearse: así conserva el carrito y lo que ya cargó. Si quien
  /// la aloja no lo usa, debe recrearla con otra `key` para cada pedido.
  final Object? request;

  /// Burbuja de perfil que pone el ParentShell junto al título.
  final Widget? profileAction;

  const ParentMenuTab({
    super.key,
    this.initialDate,
    this.initialMode = MenuMode.monthly,
    this.request,
    this.profileAction,
  });

  @override
  State<ParentMenuTab> createState() => _ParentMenuTabState();
}

class _ParentMenuTabState extends State<ParentMenuTab> {
  late MenuMode _mode = widget.initialMode;
  late bool _productsVisited = widget.initialMode == MenuMode.products;

  void _setMode(MenuMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      if (mode == MenuMode.products) _productsVisited = true;
    });
  }

  @override
  void didUpdateWidget(ParentMenuTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new request from Inicio (a day, or "Productos"): switch the view.
    final isNewRequest =
        widget.request != oldWidget.request ||
        widget.initialMode != oldWidget.initialMode ||
        widget.initialDate != oldWidget.initialDate;
    if (isNewRequest) _setMode(widget.initialMode);
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
          dateRequest: widget.request,
          headerAccessory: _switcher,
          profileAction: widget.profileAction,
        ),
        if (_productsVisited)
          ParentProductsScreen(
            headerAccessory: _switcher,
            profileAction: widget.profileAction,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
