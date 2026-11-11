import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/collapsing_header.dart';
import '../../../core/widgets/collapsing_scroll_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../menu/models/menu_models.dart';
import '../../menu/screens/product_detail_screen.dart';
import '../../menu/services/menu_service.dart';
import '../../menu/utils/cart_rules.dart';
import '../../menu/utils/catalog_filters.dart';
import '../../menu/screens/combo_detail_screen.dart';
import '../../menu/widgets/catalog_search_row.dart';
import '../../menu/widgets/catalog_title_block.dart';
import '../../menu/widgets/catalog_item_card.dart';
import '../../menu/widgets/catalog_stock_badges.dart';
import '../../menu/widgets/catalog_section.dart';
import '../../menu/widgets/category_filter_bar.dart';
import '../../menu/widgets/offers_section.dart';
import '../models/pos_identification_model.dart';
import '../providers/pos_cart_controller.dart';
import '../widgets/pos_cart_bar.dart';
import '../widgets/pos_user_banner.dart';
import 'pos_checkout_screen.dart';
import '../../../core/utils/error_message.dart';

/// selección de productos para el usuario
/// identificado. Los productos que contienen alérgenos del usuario quedan
/// bloqueados desde la selección.
class PosMenuScreen extends StatefulWidget {
  /// Cliente identificado; nulo en una venta rápida (solo efectivo).
  final IdentifiedUser? user;

  const PosMenuScreen({super.key, this.user});

  @override
  State<PosMenuScreen> createState() => _PosMenuScreenState();
}

class _PosMenuScreenState extends State<PosMenuScreen> with NotificationMixin {
  final MenuService _menuService = MenuService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<MenuItem> _items = [];
  Map<int, MenuItem> _itemsById = const {}; // índice para alérgenos de combos
  CatalogOffers _offers = CatalogOffers.empty;
  final PosCartController _cart = PosCartController();
  String _searchQuery = '';
  String? _selectedCategory; // null = todas

  late final Set<String> _userAllergies;

  @override
  void initState() {
    super.initState();
    _userAllergies = (widget.user?.allergies ?? const <String>[])
        .map((a) => a.trim().toLowerCase())
        .toSet();
    _cart.addListener(_onCartChanged);
    _loadMenu();
  }

  @override
  void dispose() {
    _cart
      ..removeListener(_onCartChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final offersFuture = _loadOffers();
      final items = await _menuService.getMenu();
      final offers = await offersFuture;
      if (!mounted) return;
      _cart.setCatalog(items);
      setState(() {
        _items = items;
        _itemsById = {for (final item in items) item.id: item};
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = errorMessageOf(e);
        _isLoading = false;
      });
    }
  }

  // The combo banner is secondary: without it the products can still be sold.
  Future<CatalogOffers> _loadOffers() async {
    try {
      return await _menuService.getActiveOffers();
    } on ApiException {
      return CatalogOffers.empty;
    }
  }

  List<String> _conflictingAllergens(MenuItem item) {
    if (_userAllergies.isEmpty) return const [];
    return item.allergens
        .where((a) => _userAllergies.contains(a.name.trim().toLowerCase()))
        .map((a) => a.name)
        .toList();
  }

  List<MenuItem> get _visibleItems =>
      filterItems(_items, category: _selectedCategory, query: _searchQuery);

  void _warnStock(String productName) => showWarningSnackBar(
    'No hay unidades suficientes de "$productName".',
    title: 'Stock insuficiente',
  );

  void _addToCart(MenuItem item, int quantity) {
    final short = _cart.addProduct(item, quantity);
    if (short != null) _warnStock(short);
  }

  /// Allergens of the customer found in the dishes of [combo].
  Set<String> _comboConflicts(Combo combo) => {
    for (final comboItem in combo.items)
      if (_itemsById[comboItem.productId] case final item?)
        ..._conflictingAllergens(item),
  };

  /// Warns that [combo] has an allergen of the customer; true if it did.
  bool _warnComboBlocked(Combo combo) {
    final conflicts = _comboConflicts(combo);
    if (conflicts.isEmpty) return false;
    AppNotificationDialog.show(
      context,
      type: NotificationType.danger,
      title: 'Combo no disponible',
      message:
          '"${combo.name}" contiene ${conflicts.join(', ')}, registrados como alergias de ${widget.user?.fullName ?? 'el cliente'}.',
    );
    return true;
  }

  /// The "Agregar combo" button adds all the combo's products at once.
  void _addCombo(Combo combo, [int quantity = 1]) {
    if (_warnComboBlocked(combo)) return;
    final short = _cart.addCombo(combo, quantity);
    if (short != null) {
      _warnStock(short);
      return;
    }
    showSuccessSnackBar(
      '"${combo.name}" se agregó al carrito.',
      title: 'Combo agregado',
    );
  }

  /// Tapping a combo opens its detail, like a normal product.
  void _openCombo(Combo combo) {
    if (_warnComboBlocked(combo)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComboDetailScreen(
          combo: combo,
          itemsById: _itemsById,
          onAdd: (qty) => _addCombo(combo, qty),
          stockBadge: CatalogStockBadges.exact,
        ),
      ),
    );
  }

  Future<void> _clearCart() async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Vaciar carrito',
      message: 'Se quitarán todos los productos seleccionados.',
      confirmLabel: 'Vaciar',
      cancelLabel: 'Conservar',
      isDestructive: true,
    );
    if (confirmed && mounted) _cart.clear();
  }

  void _showAllergenBlockedDialog(MenuItem item, List<String> conflicts) {
    AppNotificationDialog.show(
      context,
      type: NotificationType.danger,
      title: 'Producto no disponible',
      message:
          '"${item.name}" contiene ${conflicts.join(', ')}, registrados como alergias de ${widget.user?.fullName ?? 'el cliente'}. No se puede vender este producto.',
    );
  }

  void _onTapItem(MenuItem item) {
    final conflicts = _conflictingAllergens(item);
    if (conflicts.isNotEmpty) {
      _showAllergenBlockedDialog(item, conflicts);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          item: item,
          onAdd: (qty) => _addToCart(item, qty),
        ),
      ),
    );
  }

  void _onContinue() {
    if (_cart.isEmpty) return;
    // The checkout edits this same cart, so the menu stays in sync.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosCheckoutScreen(user: widget.user, cart: _cart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    // Loading and error show no products, so they count as 0.
    final items = _isLoading || _errorMessage != null
        ? const <MenuItem>[]
        : _visibleItems;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        maxWidth: AppLayout.wideMaxWidth,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondary500,
                  onRefresh: _loadMenu,
                  child: CollapsingScrollView(
                    itemCount: items.length,
                    // The search field and the customer box (allergies are
                    // safety information) stay; the title and categories
                    // shrink together with the scroll.
                    header: CollapsingHeader(
                      kept: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CatalogSearchRow(
                            showBackButton: true,
                            searchController: _searchController,
                            onSearchChanged: (value) => setState(
                              () => _searchQuery = value.trim().toLowerCase(),
                            ),
                          ),
                          if (user != null) PosUserBanner(user: user),
                        ],
                      ),
                      collapsible: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CatalogTitleBlock(title: 'Productos'),
                          _buildCategoryChips(),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                      ),
                    ),
                    slivers: _buildContent(items),
                  ),
                ),
              ),
              if (!_cart.isEmpty)
                PosCartBar(
                  total: _cart.total,
                  itemCount: _cart.itemCount,
                  onClear: _clearCart,
                  onContinue: _onContinue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = categoriesOf(_items);
    // Con una sola categoría el filtro no aporta nada.
    if (categories.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: CategoryFilterBar(
        categories: categories,
        selected: _selectedCategory,
        onSelected: (category) => setState(() => _selectedCategory = category),
      ),
    );
  }

  /// Loading, error or the section with the combos and the products, as
  /// slivers of the same scroll view as the header.
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
              onAction: _loadMenu,
            ),
          ),
        ),
      ];
    }

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
                    : 'No hay productos disponibles',
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

  /// Combos with their dishes, inside the scroll of the list. The POS sells
  /// combos; discounts already show on each product card.
  Widget? _buildOffers() {
    if (_offers.combos.isEmpty ||
        _selectedCategory != null ||
        _searchQuery.isNotEmpty) {
      return null;
    }
    return OffersSection(
      offers: CatalogOffers(combos: _offers.combos),
      itemsById: _itemsById,
      onAddCombo: _addCombo,
      onComboTap: _openCombo,
      onProductTap: _onTapItem,
      comboQuantity: (combo) => _cart.quantityOfCombo(combo.id),
      isComboBlocked: (combo) => _comboConflicts(combo).isNotEmpty,
      stockBadge: CatalogStockBadges.exact,
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final blocked = _conflictingAllergens(item).isNotEmpty;
    final inCart = _cart.quantityOfProduct(item.id);
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
        // Stock 0 = agotado, igual que lo trata el servidor.
        CatalogBadge.info('Stock: ${item.stock}'),
        if (inCart > 0)
          CatalogBadge.info(
            '$inCart en carrito',
            onRemove: CartRules.canRemoveLine(_cart.lineCount)
                ? () => _cart.removeProduct(item.id)
                : null,
          ),
      ],
    );
  }
}
