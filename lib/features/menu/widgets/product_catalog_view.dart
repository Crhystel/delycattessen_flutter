import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/collapsing_header.dart';
import '../../../core/widgets/collapsing_scroll_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/floating_bubbles.dart';
import '../models/menu_models.dart';
import '../screens/combo_detail_screen.dart';
import '../screens/product_detail_screen.dart';
import '../services/product_catalog_source.dart';
import '../utils/catalog_filters.dart';
import '../utils/low_stock_rule.dart';
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

  /// Widget a la derecha del título (la burbuja de perfil del padre).
  final Widget? titleTrailing;

  /// Cómo se muestran las categorías (burbujas con icono o chips).
  final CategoryFilterStyle categoryStyle;

  /// Fondo de la pantalla y de la cabecera que se encoge.
  final Color backgroundColor;

  /// Vista del padre: círculos decorativos arriba, buscador con borde, sin
  /// recuadro, combos en carrusel, "Productos" con su cantidad y filas con la
  /// foto a la izquierda. La cabecera va en el orden del diseño: título,
  /// selector, buscador y categorías (estas dos últimas quedan fijas).
  final bool flatLayout;

  const ProductCatalogView({
    super.key,
    required this.source,
    this.title = 'Productos',
    this.showBackButton = false,
    this.headerAccessory,
    this.banner,
    this.onRefreshed,
    this.titleTrailing,
    this.categoryStyle = CategoryFilterStyle.circles,
    this.backgroundColor = Colors.white,
    this.flatLayout = false,
  });

  @override
  State<ProductCatalogView> createState() => _ProductCatalogViewState();
}

class _ProductCatalogViewState extends State<ProductCatalogView> {
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
    } catch (_) {
      // Network, backend or a malformed offer: the catalog goes on without it.
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

  Widget _buildCategories(List<String> categories) => CategoryFilterBar(
    categories: categories,
    style: widget.categoryStyle,
    selected: _selectedCategory,
    onSelected: (category) => setState(() => _selectedCategory = category),
  );

  /// Header of the parent view, in the order of the design (title, selector,
  /// search, categories). When scrolling, title, selector and categories fold
  /// away and only the search field stays pinned; the bubbles are drawn behind
  /// the pinned band too, so they look the same as at the top of the page.
  Widget _buildFlatHeader(
    List<String> categories,
    bool showFilters,
    double topInset,
  ) {
    return CollapsingHeader(
      backgroundColor: widget.backgroundColor,
      transparentAtTop: true,
      topInset: topInset,
      backdrop: const FloatingBubbles(
        corner: BubbleCorner.topRight,
        design: true,
      ),
      collapsible: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatalogTitleBlock(
            design: true,
            title: widget.title,
            accessory: widget.headerAccessory,
            trailing: widget.titleTrailing,
          ),
          if (widget.banner != null) widget.banner!,
        ],
      ),
      kept: CatalogSearchRow(
        hintText: 'Buscar productos',
        outlined: true,
        design: true,
        showBackButton: widget.showBackButton,
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
      ),
      // Always given (empty while loading or without categories): it is what
      // keeps the order title, selector, search; with null the header would
      // fall back to the old one and put the search field on top.
      collapsibleBelow: showFilters && categories.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: _buildCategories(categories),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = categoriesOf(_items);
    final showFilters = !_isLoading && _errorMessage == null;
    final flat = widget.flatLayout;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    // Loading and error show no products, so they count as 0.
    final items = showFilters
        ? filterItems(_items, category: _selectedCategory, query: _searchQuery)
        : const <MenuItem>[];

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Stack(
        children: [
          if (flat)
            const RepaintBoundary(
              child: FloatingBubbles(
                corner: BubbleCorner.topRight,
                design: true,
              ),
            ),
          ResponsiveCenter(
            maxWidth: AppLayout.wideMaxWidth,
            // The parent view is drawn edge to edge: its header adds the
            // status bar inset itself and stays pinned under it.
            child: SafeArea(
              top: !flat,
              child: RefreshIndicator(
                color: AppColors.secondary500,
                edgeOffset: flat ? topInset : 0,
                onRefresh: _refresh,
                // The header always folds completely once there are 2+
                // products (the offers do not count).
                child: CollapsingScrollView(
                  itemCount: items.length,
                  // The search field stays; the title, selector, banner and
                  // categories shrink together with the scroll and come back
                  // when the list returns to its start.
                  header: flat
                      ? _buildFlatHeader(categories, showFilters, topInset)
                      : CollapsingHeader(
                          backgroundColor: widget.backgroundColor,
                          kept: CatalogSearchRow(
                            hintText: 'Buscar...',
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
                                trailing: widget.titleTrailing,
                              ),
                              if (widget.banner != null) widget.banner!,
                              const SizedBox(height: AppSpacing.sm),
                              if (showFilters && categories.isNotEmpty)
                                _buildCategories(categories),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ),
                        ),
                  slivers: _buildContent(items),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loading, error or the section with the offers and the products. All of
  /// them are slivers of the same scroll view as the header.
  List<Widget> _buildContent(List<MenuItem> items) {
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

    final offers = _buildOffers();
    if (widget.flatLayout) return _buildFlatContent(items, offers);
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
            SliverToBoxAdapter(child: _buildEmptyItems())
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

  /// Parent layout: the combo carousel, then "Productos" with how many there
  /// are and a row per product, with no box around them.
  List<Widget> _buildFlatContent(List<MenuItem> items, Widget? offers) {
    return [
      if (offers != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              0,
            ),
            child: offers,
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Productos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sectionTitleSm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                items.length == 1
                    ? '1 disponible'
                    : '${items.length} disponibles',
                style: AppText.secondaryLg,
              ),
            ],
          ),
        ),
      ),
      if (items.isEmpty)
        SliverToBoxAdapter(child: _buildEmptyItems())
      else
        SliverResponsiveItemList(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          itemCount: items.length,
          itemBuilder: (_, index) => _buildItemCard(items[index]),
        ),
    ];
  }

  Widget _buildEmptyItems() {
    return EmptyState(
      icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.fastfood,
      title: _searchQuery.isNotEmpty
          ? 'No encontramos "$_searchQuery"'
          : 'Tu sede aún no tiene productos disponibles',
      message: _searchQuery.isNotEmpty ? 'Prueba con otro término.' : null,
    );
  }

  /// Offers go inside the scroll of the list, so they never shrink it. They
  /// show only without a search or a category filter. This catalog only
  /// informs, so a sold out combo does not appear.
  Widget? _buildOffers() {
    final offers = CatalogOffers(combos: _offers.visibleCombos);
    if (offers.isEmpty ||
        _selectedCategory != null ||
        _searchQuery.isNotEmpty) {
      return null;
    }
    final itemsById = {for (final item in _items) item.id: item};
    return OffersSection(
      offers: offers,
      itemsById: itemsById,
      carousel: widget.flatLayout,
      onComboTap: (combo) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComboDetailScreen(combo: combo, itemsById: itemsById),
        ),
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
      leadingImage: widget.flatLayout,
      onTap: () => _onTapItem(item),
      badges: [
        if (blocked) const CatalogBadge.allergen(),
        if (widget.flatLayout && item.stock == 1)
          const CatalogBadge(
            label: '¡Queda 1!',
            background: AppColors.dangerBg,
            foreground: AppColors.danger700,
          )
        else if (LowStockRule.isLow(item.stock))
          CatalogBadge.info('Quedan ${item.stock}'),
      ],
    );
  }
}
