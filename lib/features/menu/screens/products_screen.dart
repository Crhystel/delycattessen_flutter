import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_picker_sheet.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import '../widgets/catalog_filters.dart';
import '../widgets/catalog_item_card.dart';
import '../widgets/catalog_search_field.dart';
import '../widgets/category_filter_bar.dart';
import 'product_detail_screen.dart';

/// Catálogo de productos de la sede del hijo seleccionado (vista del padre).
/// Es de solo consulta: el backend únicamente permite preordenar platillos
/// del menú mensual, así que aquí no hay carrito.
class ProductsScreen extends StatefulWidget {
  /// true cuando vive dentro del ParentShell: sin flecha atrás.
  final bool embedded;

  /// Widget bajo el título (selector Menú/Productos).
  final Widget? headerAccessory;

  const ProductsScreen({super.key, this.embedded = false, this.headerAccessory});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const int _lowStockThreshold = 5;

  final MenuService _menuService = MenuService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late final ChildrenProvider _childrenProvider;

  bool _isLoading = true;
  String? _errorMessage;
  List<MenuItem> _items = [];
  Set<int> _childAllergenIds = {};
  Child? _selectedChild;
  String _searchQuery = '';
  String? _selectedCategory; // null = todas
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _childrenProvider = context.read<ChildrenProvider>();
    _childrenProvider.addListener(_onSelectedChildChanged);
    Future.microtask(() async {
      await _childrenProvider.ensureLoaded();
      if (!mounted) return;
      _onSelectedChildChanged();
    });
  }

  @override
  void dispose() {
    _childrenProvider.removeListener(_onSelectedChildChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Mantiene el catálogo alineado con el hijo seleccionado global: cada hijo
  /// puede pertenecer a una sede distinta con sus propios productos.
  void _onSelectedChildChanged() {
    if (!mounted) return;
    final selected = _childrenProvider.selectedChild;
    if (selected == null) {
      if (_isLoading) setState(() => _isLoading = false);
      return;
    }
    if (selected.id != _selectedChild?.id) {
      setState(() {
        _selectedChild = selected;
        _selectedCategory = null;
      });
      _load();
    } else if (!identical(selected, _selectedChild)) {
      setState(() => _selectedChild = selected);
    }
  }

  Future<void> _load() async {
    final child = _selectedChild;
    if (child == null) return;
    final token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _menuService.getMenu(studentId: child.id),
        _authService.getStudentAllergies(child.id),
      ]);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _items = results[0] as List<MenuItem>;
        _childAllergenIds = (results[1] as List<Allergen>)
            .map((a) => a.id)
            .toSet();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
    await _childrenProvider.refresh();
  }

  List<String> _conflictingAllergens(MenuItem item) => item.allergens
      .where((a) => _childAllergenIds.contains(a.id))
      .map((a) => a.name)
      .toList();

  void _onSearchChanged(String value) {
    setState(() {}); // refresca el botón de limpiar
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  void _onTapItem(MenuItem item) {
    final conflicts = _conflictingAllergens(item);
    if (conflicts.isNotEmpty) {
      final child = _selectedChild;
      final childName = child != null
          ? '${child.firstName} ${child.lastName}'
          : 'este estudiante';
      AppNotificationDialog.show(
        context,
        type: NotificationType.danger,
        title: 'Producto no disponible',
        message:
            '"${item.name}" contiene ${conflicts.join(', ')}, registrados como alergias de $childName.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(item: item)),
    );
  }

  void _openChildSwitcher(List<Child> children) {
    if (children.length <= 1) return;
    ChildPickerSheet.show(
      context,
      _childrenProvider,
      title: '¿Para quién estás viendo?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = context.watch<ChildrenProvider>().children;
    final categories = categoriesOf(_items);
    final showFilters = !_isLoading && _errorMessage == null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_selectedChild != null) _buildChildBanner(children),
            const SizedBox(height: AppSpacing.sm),
            if (showFilters && categories.isNotEmpty)
              CategoryFilterBar(
                categories: categories,
                selected: _selectedCategory,
                onSelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.embedded) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                'Menú',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
          if (widget.headerAccessory != null) ...[
            const SizedBox(height: AppSpacing.sm),
            widget.headerAccessory!,
          ],
          const SizedBox(height: AppSpacing.sm),
          CatalogSearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildChildBanner(List<Child> children) {
    final canSwitch = children.length > 1;
    final child = _selectedChild!;
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
          onTap: canSwitch ? () => _openChildSwitcher(children) : null,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary500),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar los productos',
          message: _errorMessage,
          actionLabel: 'Reintentar',
          onAction: _load,
        ),
      );
    }

    final items = filterItems(
      _items,
      category: _selectedCategory,
      query: _searchQuery,
    );
    return RefreshIndicator(
      color: AppColors.secondary500,
      onRefresh: _refresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.fastfood,
                  title: _searchQuery.isNotEmpty
                      ? 'No encontramos "$_searchQuery"'
                      : 'Esta sede aún no tiene productos disponibles',
                  message: _searchQuery.isNotEmpty
                      ? 'Prueba con otro término.'
                      : null,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length,
              itemBuilder: (_, index) => _buildItemCard(items[index]),
            ),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final blocked = _conflictingAllergens(item).isNotEmpty;
    return CatalogItemCard(
      name: item.name,
      description: item.description,
      price: item.price,
      imageUrl: item.imageUrl,
      dimmed: blocked,
      onTap: () => _onTapItem(item),
      badges: [
        if (blocked) const CatalogBadge.allergen(),
        if (item.stock > 0 && item.stock <= _lowStockThreshold)
          CatalogBadge.info('Quedan ${item.stock}'),
      ],
    );
  }
}
