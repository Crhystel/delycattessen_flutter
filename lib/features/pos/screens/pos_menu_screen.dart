import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import '../../../core/widgets/empty_state.dart';
import '../../menu/models/menu_models.dart';
import '../../menu/screens/product_detail_screen.dart';
import '../../menu/services/menu_service.dart';
import '../../menu/utils/cart_rules.dart';
import '../../menu/utils/catalog_filters.dart';
import '../../menu/widgets/catalog_header.dart';
import '../../menu/widgets/catalog_item_card.dart';
import '../../menu/widgets/catalog_section.dart';
import '../../menu/widgets/category_filter_bar.dart';
import '../models/pos_identification_model.dart';
import 'pos_checkout_screen.dart';

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
  Map<int, MenuItem> _itemsById = const {}; // índice para total/carrito
  final Map<int, int> _cart = {}; // itemId -> quantity
  String _searchQuery = '';
  String? _selectedCategory; // null = todas

  late final Set<String> _userAllergies;

  @override
  void initState() {
    super.initState();
    _userAllergies = (widget.user?.allergies ?? const <String>[])
        .map((a) => a.trim().toLowerCase())
        .toSet();
    _loadMenu();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _menuService.getMenu();
      if (!mounted) return;
      setState(() {
        _items = items;
        _itemsById = {for (final item in items) item.id: item};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
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

  double get _total {
    var total = 0.0;
    for (final entry in _cart.entries) {
      final item = _itemsById[entry.key];
      if (item != null) total += item.price * entry.value;
    }
    return total;
  }

  int get _cartCount => _cart.values.fold(0, (sum, q) => sum + q);

  void _addToCart(MenuItem item, int quantity) {
    final current = _cart[item.id] ?? 0;
    if (item.stock > 0 && current + quantity > item.stock) {
      showWarningSnackBar(
        'Solo hay ${item.stock} unidades disponibles de "${item.name}".',
        title: 'Stock insuficiente',
      );
      return;
    }
    setState(() => _cart[item.id] = current + quantity);
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
    if (confirmed && mounted) setState(() => _cart.clear());
  }

  /// Quita el producto completo del carrito, sin importar su cantidad.
  void _removeFromCart(int itemId) {
    setState(() => _cart.remove(itemId));
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
    final lines = [
      for (final entry in _cart.entries)
        if (_itemsById[entry.key] case final item?)
          CheckoutLine(item: item, quantity: entry.value),
    ];
    if (lines.isEmpty) return;
    Navigator.push<Map<int, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => PosCheckoutScreen(user: widget.user, lines: lines),
      ),
    ).then((updatedCart) {
      // El checkout devuelve el carrito editado (quitar/ajustar líneas).
      if (!mounted || updatedCart == null) return;
      setState(() {
        _cart
          ..clear()
          ..addAll(updatedCart);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (widget.user != null) _buildUserBanner(widget.user!),
            _buildCategoryChips(),
            const SizedBox(height: AppSpacing.xs),
            Expanded(child: _buildBody()),
            if (_cart.isNotEmpty) _buildCartBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return CatalogHeader(
      title: 'Productos',
      showBackButton: true,
      searchController: _searchController,
      onSearchChanged: (value) =>
          setState(() => _searchQuery = value.trim().toLowerCase()),
    );
  }

  Widget _buildUserBanner(IdentifiedUser user) {
    final hasAllergies = user.allergies.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasAllergies ? AppColors.dangerBg : AppColors.secondary50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendiendo a ${user.fullName} · \$${user.balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            if (hasAllergies) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.danger700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Alergias: ${user.allergies.join(', ')}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
          onAction: _loadMenu,
        ),
      );
    }

    final items = _visibleItems;
    final list = RefreshIndicator(
      color: AppColors.secondary500,
      onRefresh: _loadMenu,
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
                      : 'No hay productos disponibles',
                  message: _searchQuery.isNotEmpty
                      ? 'Prueba con otro término.'
                      : null,
                ),
              ],
            )
          : ListView.builder(
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
    return CatalogSection(
      title: CategoryFilterBar.labelFor(_selectedCategory),
      child: list,
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final blocked = _conflictingAllergens(item).isNotEmpty;
    final inCart = _cart[item.id] ?? 0;
    return CatalogItemCard(
      name: item.name,
      description: item.description,
      price: item.price,
      imageUrl: item.imageUrl,
      dimmed: blocked,
      onTap: () => _onTapItem(item),
      badges: [
        if (blocked) const CatalogBadge.allergen(),
        if (inCart > 0)
          CatalogBadge.info(
            '$inCart en carrito',
            onRemove: CartRules.canRemoveLine(_cart.length)
                ? () => _removeFromCart(item.id)
                : null,
          ),
      ],
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Vaciar carrito',
            onPressed: _clearCart,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger700),
          ),
          Expanded(
            child: Text(
              '\$${_total.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary500,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: _onContinue,
            child: Text(
              'Continuar ($_cartCount)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
