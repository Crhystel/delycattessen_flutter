import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/auth_models.dart';
import '../../children/providers/children_provider.dart';
import '../services/product_catalog_source.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_catalog_view.dart';

/// Catálogo de productos de la sede del hijo seleccionado (vista del padre).
/// Solo se ocupa de qué hijo está elegido; la UI vive en [ProductCatalogView].
class ParentProductsScreen extends StatefulWidget {
  /// Widget bajo el título (selector Menú/Productos).
  final Widget? headerAccessory;

  /// Burbuja de perfil a la derecha del título (la pone el ParentShell).
  final Widget? profileAction;

  const ParentProductsScreen({
    super.key,
    this.headerAccessory,
    this.profileAction,
  });

  @override
  State<ParentProductsScreen> createState() => _ParentProductsScreenState();
}

class _ParentProductsScreenState extends State<ParentProductsScreen> {
  late final ChildrenProvider _childrenProvider;
  ProductCatalogSource? _source;
  Child? _child;

  @override
  void initState() {
    super.initState();
    _childrenProvider = context.read<ChildrenProvider>();
    _childrenProvider.addListener(_syncSelectedChild);
    Future.microtask(() async {
      await _childrenProvider.ensureLoaded();
      if (!mounted) return;
      _syncSelectedChild();
    });
  }

  @override
  void dispose() {
    _childrenProvider.removeListener(_syncSelectedChild);
    super.dispose();
  }

  /// Cada hijo puede pertenecer a otra sede: al cambiar de hijo cambia la fuente.
  void _syncSelectedChild() {
    if (!mounted) return;
    final selected = _childrenProvider.selectedChild;
    if (selected == null) return;
    if (selected.id != _child?.id) {
      setState(() {
        _child = selected;
        _source = StudentCatalogSource(
          studentId: selected.id,
          studentName: selected.firstName,
        );
      });
    } else if (!identical(selected, _child)) {
      setState(() => _child = selected); // saldo/foto actualizados
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se observa el provider para repintar la barra al cambiar de hijo.
    context.watch<ChildrenProvider>();
    return ProductCatalogView(
      source: _source,
      // The tab is called "Menú" in the design (the switch under it picks
      // between the monthly menu and the products).
      title: 'Menú',
      headerAccessory: widget.headerAccessory,
      titleTrailing: widget.profileAction,
      categoryStyle: CategoryFilterStyle.evenCircles,
      backgroundColor: AppColors.ink50,
      flatLayout: true,
      onRefreshed: _childrenProvider.refresh,
    );
  }
}
