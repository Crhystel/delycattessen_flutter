import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/collapsing_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/menu_models.dart';
import '../screens/combo_detail_screen.dart';
import '../screens/product_detail_screen.dart';
import '../services/product_catalog_source.dart';
import '../utils/catalog_filters.dart';
import 'catalog_item_card.dart';
import 'catalog_search_row.dart';
import 'catalog_section.dart';
import 'catalog_title_block.dart';
import 'category_filter_bar.dart';
import 'offers_section.dart';
import '../../../core/utils/error_message.dart';

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
  CatalogOffers _offers = CatalogOffers.empty;
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
        _offers = CatalogOffers.empty;
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
      // Peticiones en paralelo con Future.wait: si una falla (p. ej. cuenta
      // desactivada), el error de las demás no queda sin capturar.
      final results = await Future.wait<Object>([
        source.loadItems(),
        source.loadAllergenIds(),
        _loadOffers(source),
      ]);
      final items = results[0] as List<MenuItem>;
      final allergenIds = results[1] as Set<int>;
      final offers = results[2] as CatalogOffers;
      if (!mounted || token != _loadToken) return;
      setState(() {
        _items = items;
        _allergenIds = allergenIds;
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _errorMessage = errorMessageOf(e);
        _isLoading = false;
      });
    }
  }

  // The banner is secondary: if the offers fail to load, the catalog is
  // still shown, just without the banner.
  Future<CatalogOffers> _loadOffers(ProductCatalogSource source) async {
    try {
      return await source.loadOffers();
    } on ApiException {
      return CatalogOffers.empty;
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
          child: RefreshIndicator(
            color: AppColors.secondary500,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // The search field stays; the title, selector, banner and
                // categories shrink together with the scroll (1 to 1 with the
                // finger) and come back when the list returns to its start.
                CollapsingHeader(
                  kept: CatalogSearchRow(
                    showBackButton: widget.showBackButton,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                  ),
                  collapsible: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CatalogTitleBlock(
                        title: widget.title,
                        accessory: widget.headerAccessory,
                      ),
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
                    ],
                  ),
                ),
                ..._buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Loading, error or the section with the offers and the products. All of
  /// them are slivers of the same scroll view as the header.
  List<Widget> _buildContent() {
    if (_isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.secondary500),
          ),
        ),
      ];
    }
    if (_errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'No pudimos cargar los productos',
              message: _errorMessage,
              actionLabel: 'Reintentar',
              onAction: _load,
            ),
          ),
        ),
      ];
    }

    final items = filterItems(
      _items,
      category: _selectedCategory,
      query: _searchQuery,
    );
    final offers = _buildOffers();
    return [
      CatalogSectionSliver(
        title: CategoryFilterBar.labelFor(_selectedCategory),
        slivers: [
          if (offers != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: offers,
              ),
            ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
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
            )
          else
            SliverResponsiveItemList(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              itemCount: items.length,
              itemBuilder: (_, index) => _buildItemCard(items[index]),
            ),
        ],
      ),
    ];
  }

  /// Offers go inside the scroll of the list, so they never shrink it. They
  /// show only without a search or a category filter.
  Widget? _buildOffers() {
    if (_offers.isEmpty ||
        _selectedCategory != null ||
        _searchQuery.isNotEmpty) {
      return null;
    }
    final itemsById = {for (final item in _items) item.id: item};
    return OffersSection(
      offers: _offers,
      itemsById: itemsById,
      onComboTap: (combo) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComboDetailScreen(combo: combo, itemsById: itemsById),
        ),
      ),
      onProductTap: _onTapItem,
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final blocked = _conflictingAllergens(item).isNotEmpty;
    return CatalogItemCard(
      name: item.name,
      description: item.description,
      price: item.price,
      originalPrice: item.hasDiscount ? item.originalPrice : null,
      imageUrl: item.imageUrl,
      dimmed: blocked,
      onTap: () => _onTapItem(item),
      badges: [
        if (blocked) const CatalogBadge.allergen(),
        if (item.discountPercentage != null)
          CatalogBadge.discount(item.discountPercentage!),
        if (item.stock > 0 && item.stock <= _lowStockThreshold)
          CatalogBadge.info('Quedan ${item.stock}'),
      ],
    );
  }
}
