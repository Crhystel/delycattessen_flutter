import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/menu_models.dart';
import '../screens/product_detail_screen.dart';
import '../services/product_catalog_source.dart';
import '../utils/catalog_filters.dart';
import 'catalog_header.dart';
import 'catalog_item_card.dart';
import 'catalog_section.dart';
import 'category_filter_bar.dart';

/// Catálogo de productos de solo consulta (el backend únicamente permite
/// preordenar platillos del menú mensual). Es genérico: de dónde salen los
/// productos y las alergias lo decide [source]; con [source] nulo no hay nada
/// que cargar (p. ej. un padre sin hijo seleccionado).
class ProductCatalogView extends StatefulWidget {
  final ProductCatalogSource? source;
  final String title;
  final bool showBackButton;

  /// Widget bajo el título (p. ej. el selector Menú/Productos).
  final Widget? headerAccessory;

  /// Widget bajo el buscador (p. ej. el banner del hijo seleccionado).
  final Widget? banner;

  /// Se ejecuta tras recargar con pull-to-refresh (p. ej. refrescar saldos).
  final Future<void> Function()? onRefreshed;

  const ProductCatalogView({
    super.key,
    required this.source,
    this.title = 'Productos',
    this.showBackButton = false,
    this.headerAccessory,
    this.banner,
    this.onRefreshed,
  });

  @override
  State<ProductCatalogView> createState() => _ProductCatalogViewState();
}

class _ProductCatalogViewState extends State<ProductCatalogView> {
  static const int _lowStockThreshold = 5;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = false;
  String? _errorMessage;
  List<MenuItem> _items = const [];
  Set<int> _allergenIds = const {};
  String _searchQuery = '';
  String? _selectedCategory; // null = todas
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProductCatalogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source?.id != widget.source?.id) {
      // Otra sede/persona: se reinicia el filtro y se recarga.
      _selectedCategory = null;
      _load();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final source = widget.source;
    final token = ++_loadToken;
    if (source == null) {
      setState(() {
        _items = const [];
        _allergenIds = const {};
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Peticiones en paralelo; se esperan por separado para conservar los tipos.
      final itemsFuture = source.loadItems();
      final allergensFuture = source.loadAllergenIds();
      final items = await itemsFuture;
      final allergenIds = await allergensFuture;
      if (!mounted || token != _loadToken) return;
      setState(() {
        _items = items;
        _allergenIds = allergenIds;
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
    await widget.onRefreshed?.call();
  }

  List<String> _conflictingAllergens(MenuItem item) => item.allergens
      .where((a) => _allergenIds.contains(a.id))
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
      AppNotificationDialog.show(
        context,
        type: NotificationType.danger,
        title: 'Producto no disponible',
        message:
            '"${item.name}" contiene ${conflicts.join(', ')}, registrados en '
            '${widget.source?.allergyOwnerLabel ?? 'las alergias'}.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = categoriesOf(_items);
    final showFilters = !_isLoading && _errorMessage == null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        maxWidth: AppLayout.wideMaxWidth,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (widget.banner != null) widget.banner!,
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
      ),
    );
  }

  Widget _buildHeader() {
    return CatalogHeader(
      title: widget.title,
      showBackButton: widget.showBackButton,
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      accessory: widget.headerAccessory,
    );
  }

  Widget _buildBody() {
    if (_isLoading || _errorMessage != null) return _buildList();
    return CatalogSection(
      title: CategoryFilterBar.labelFor(_selectedCategory),
      child: _buildList(),
    );
  }

  Widget _buildList() {
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
                      : 'Tu sede aún no tiene productos disponibles',
                  message: _searchQuery.isNotEmpty
                      ? 'Prueba con otro término.'
                      : null,
                ),
              ],
            )
          : ResponsiveItemList(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
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
