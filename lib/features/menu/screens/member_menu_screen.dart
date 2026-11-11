import 'package:flutter/material.dart';

import '../providers/parent_menu_controller.dart';
import '../utils/allergen_advisory.dart';
import '../widgets/monthly_menu_view.dart';

/// Menú del mes del estudiante, de solo lectura: ve los días y los platillos
/// con sus alérgenos, pero no puede agregar al carrito ni confirmar pedidos
/// (los pedidos los hace el padre). Es la misma vista del padre
/// ([MonthlyMenuView]) sin acciones de pedido; un día bloqueado por el control
/// parental también se puede leer.
class MemberMenuScreen extends StatefulWidget {
  const MemberMenuScreen({super.key, this.menuController});

  /// Por defecto la pantalla crea (y libera) el suyo; las pruebas inyectan uno
  /// con un servicio simulado.
  final ParentMenuController? menuController;

  @override
  State<MemberMenuScreen> createState() => _MemberMenuScreenState();
}

class _MemberMenuScreenState extends State<MemberMenuScreen> {
  late final ParentMenuController _menu =
      widget.menuController ?? ParentMenuController();

  @override
  void initState() {
    super.initState();
    _menu.loadOwn();
  }

  @override
  void dispose() {
    if (widget.menuController == null) _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MonthlyMenuView(
      menu: _menu,
      title: 'Menú del mes',
      showBackButton: true,
      allergenAudience: AllergenAudience.self,
      onRefresh: _menu.loadOwn,
      onRetry: _menu.loadOwn,
    );
  }
}
