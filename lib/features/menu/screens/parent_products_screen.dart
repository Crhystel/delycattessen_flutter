import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../../auth/models/auth_models.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_picker_sheet.dart';
import '../services/product_catalog_source.dart';
import '../widgets/product_catalog_view.dart';

/// Catálogo de productos de la sede del hijo seleccionado (vista del padre).
/// Solo se ocupa de qué hijo está elegido; la UI vive en [ProductCatalogView].
class ParentProductsScreen extends StatefulWidget {
  /// Widget bajo el título (selector Menú/Productos).
  final Widget? headerAccessory;

  const ParentProductsScreen({super.key, this.headerAccessory});

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
    final children = context.watch<ChildrenProvider>().children;
    final child = _child;
    return ProductCatalogView(
      source: _source,
      headerAccessory: widget.headerAccessory,
      banner: child == null ? null : _buildChildBanner(child, children),
      onRefreshed: _childrenProvider.refresh,
    );
  }

  Widget _buildChildBanner(Child child, List<Child> children) {
    final canSwitch = children.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: canSwitch
              ? () => ChildPickerSheet.show(
                  context,
                  _childrenProvider,
                  title: '¿Para quién estás viendo?',
                )
              : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            decoration: BoxDecoration(
              color: AppColors.secondary50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChildAvatarChip(imageUrl: child.profilePictureUrl, radius: 12),
                const SizedBox(width: 8),
                Text(
                  'Productos para ${child.firstName}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary700,
                  ),
                ),
                if (canSwitch) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: AppColors.secondary700,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
