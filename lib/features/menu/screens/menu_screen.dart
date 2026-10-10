import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../children/providers/children_provider.dart';
import '../../children/widgets/child_picker_sheet.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuScreen extends StatefulWidget {
  final int? studentId;

  /// true cuando vive dentro del ParentShell: sin flecha atrás ni barra propia.
  final bool embedded;

  const MenuScreen({super.key, this.studentId, this.embedded = false});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with NotificationMixin {
  final MenuService _menuService = MenuService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  final Map<int, int> _cart = {}; // itemId -> quantity
  String? _selectedCategory; // null = todas las categorías
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  Child? _selectedChild;
  Set<int> _childAllergenIds = {};
  bool _hasInitializedSelectedChild = false;
  late final ChildrenProvider _childrenProvider;

  static const Map<String, IconData> _categoryIcons = {
    'bar': Icons.local_bar,
    'almuerzo': Icons.restaurant_menu,
    'snacks': Icons.lunch_dining,
    'bebidas': Icons.local_drink,
    'postres': Icons.icecream,
  };

  /// Categorías reales del menú, en el orden en que llegan del backend.
  List<String> get _categoryNames {
    final seen = <String>{};
    return [
      for (final item in _menuItems)
        if (item.category.isNotEmpty && seen.add(item.category)) item.category,
    ];
  }

  IconData _iconFor(String category) =>
      _categoryIcons[category.toLowerCase()] ?? Icons.restaurant;

  @override
  void initState() {
    super.initState();
    _childrenProvider = context.read<ChildrenProvider>();
    _childrenProvider.addListener(_onSelectedChildChanged);
    _fetchMenu();
    Future.microtask(() async {
      await _childrenProvider.ensureLoaded();
      _initializeSelectedChild();
    });
  }

  @override
  void dispose() {
    _childrenProvider.removeListener(_onSelectedChildChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Mantiene este Menú alineado con el hijo seleccionado global (cambiado
  /// desde Inicio, Pedidos o Billetera) y con su saldo actualizado.
  void _onSelectedChildChanged() {
    if (!mounted || !_hasInitializedSelectedChild) return;
    final selected = _childrenProvider.selectedChild;
    if (selected == null) return;
    if (selected.id != _selectedChild?.id) {
      _switchChild(selected);
    } else if (!identical(selected, _selectedChild)) {
      setState(() => _selectedChild = selected);
    }
  }

  void _initializeSelectedChild() {
    if (_hasInitializedSelectedChild || !mounted) return;
    if (widget.studentId != null) {
      _childrenProvider.select(widget.studentId!);
    }
    final initial = _childrenProvider.selectedChild;
    if (initial == null) return;

    setState(() {
      _selectedChild = initial;
      _hasInitializedSelectedChild = true;
    });
    _loadChildAllergies(initial.id);
  }

  Future<void> _refreshSelectedChildBalance() async {
    await context.read<ChildrenProvider>().refresh();
    if (!mounted) return;
    final children = context.read<ChildrenProvider>().children;
    if (children.isEmpty) return;
    final updated = children.firstWhere(
      (c) => c.id == _selectedChild?.id,
      orElse: () => children.first,
    );
    setState(() => _selectedChild = updated);
  }

  Future<void> _loadChildAllergies(int studentId) async {
    try {
      final allergies = await _authService.getStudentAllergies(studentId);
      if (!mounted) return;
      setState(() {
        _childAllergenIds = allergies.map((a) => a.id).toSet();
      });
    } catch (_) {
      if (mounted) setState(() => _childAllergenIds = {});
    }
  }

  Future<void> _refreshMenu() async {
    await Future.wait([
      _fetchMenu(),
      if (_selectedChild != null) _loadChildAllergies(_selectedChild!.id),
    ]);
  }

  Future<void> _fetchMenu() async {
    try {
      final items = await _menuService.getMenu();
      if (!mounted) return;
      setState(() => _menuItems = items);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        title: 'No se pudo cargar el menú',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToCart(int itemId, int quantity) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + quantity;
    });
  }

  bool _isUnsafeForChild(MenuItem item) {
    if (_childAllergenIds.isEmpty) return false;
    return item.allergens.any((a) => _childAllergenIds.contains(a.id));
  }

  Set<String> _unsafeAllergenNames(MenuItem item) {
    return item.allergens
        .where((a) => _childAllergenIds.contains(a.id))
        .map((a) => a.name)
        .toSet();
  }

  void _showAllergenBlockedDialog(MenuItem item) {
    final childName = _selectedChild != null
        ? '${_selectedChild!.firstName} ${_selectedChild!.lastName}'
        : 'este hijo';
    final allergenNames = _unsafeAllergenNames(item).join(', ');

    AppNotificationDialog.show(
      context,
      type: NotificationType.danger,
      title: 'No disponible para $childName',
      message:
          '"${item.name}" contiene $allergenNames, registrado como alergia '
          'de $childName. No se puede agregar al carrito.',
    );
  }

  void _openChildSwitcher(List<Child> children) {
    if (children.length <= 1) return;
    ChildPickerSheet.show(
      context,
      _childrenProvider,
      title: '¿Para quién estás pidiendo?',
    );
  }

  Future<void> _switchChild(Child child) async {
    if (child.id == _selectedChild?.id) return;

    final hadItemsInCart = _cart.isNotEmpty;
    setState(() {
      _selectedChild = child;
      _cart.clear();
      _childAllergenIds = {};
    });
    await _loadChildAllergies(child.id);

    if (!mounted) return;
    if (hadItemsInCart) {
      showInfoSnackBar('Se vació el carrito al cambiar de hijo.');
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  /// Con búsqueda activa se busca en todo el menú; si no, filtra por categoría.
  List<MenuItem> get _visibleItems {
    if (_searchQuery.isNotEmpty) {
      return _menuItems
          .where((i) => i.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (_selectedCategory == null) return _menuItems;
    return _menuItems.where((i) => i.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final children = context.watch<ChildrenProvider>().children;
    final total = _cart.entries.fold<double>(0, (sum, entry) {
      final matches = _menuItems.where((i) => i.id == entry.key);
      if (matches.isEmpty) return sum;
      return sum + (matches.first.price * entry.value);
    });

    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_selectedChild != null) _buildChildBanner(children),
            _buildCategories(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.teal500,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.teal500,
                      onRefresh: _refreshMenu,
                      child: _buildProductList(),
                    ),
            ),
            if (total > 0) _buildCartSummary(total),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          if (!widget.embedded)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.ink900),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '¿Qué se te antoja hoy?',
                prefixIcon: const Icon(Icons.search, color: AppColors.teal700),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _onSearchChanged('');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
                  'Pidiendo para ${child.firstName} · \$${(child.balance ?? 0).toStringAsFixed(2)}',
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

  Widget _buildCategories() {
    final names = _categoryNames;
    if (names.isEmpty) return const SizedBox(height: AppSpacing.md);
    final options = <String?>[null, ...names];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = options[index];
          final isSelected = _selectedCategory == category;
          return ChoiceChip(
            showCheckmark: false,
            selected: isSelected,
            selectedColor: AppColors.teal500,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.teal500 : AppColors.teal50,
            ),
            shape: const StadiumBorder(),
            avatar: Icon(
              category == null ? Icons.apps : _iconFor(category),
              size: 18,
              color: isSelected ? Colors.white : AppColors.secondary500,
            ),
            label: Text(
              category ?? 'Todo',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.ink900,
              ),
            ),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    final items = _visibleItems;

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.restaurant,
            title: _searchQuery.isNotEmpty
                ? 'No encontramos "$_searchQuery"'
                : 'No hay productos en esta categoría',
            message: _searchQuery.isNotEmpty ? 'Prueba con otro nombre.' : null,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildProductCard(items[index]),
    );
  }

  Widget _buildProductCard(MenuItem item) {
    final isUnsafe = _isUnsafeForChild(item);
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: isUnsafe ? 0.6 : 1.0,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () {
          if (isUnsafe) {
            _showAllergenBlockedDialog(item);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                item: item,
                onAdd: (qty) => _addToCart(item.id, qty),
              ),
            ),
          );
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink900.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.brand700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isUnsafe) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: AppColors.danger700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Alérgeno',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.danger700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: Container(
                width: 100,
                height: 75,
                color: AppColors.ink50,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        placeholder: (_, _) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.teal500,
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.fastfood,
                          color: AppColors.teal500,
                        ),
                      )
                    : const Icon(Icons.fastfood, color: AppColors.teal500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 32),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    studentId: _selectedChild?.id ?? widget.studentId ?? 0,
                    cart: _cart,
                    menuItems: _menuItems,
                    childAllergenIds: _childAllergenIds,
                    childName: _selectedChild != null
                        ? '${_selectedChild!.firstName} ${_selectedChild!.lastName}'
                        : '',
                    childBalance: _selectedChild?.balance,
                  ),
                ),
              ).then((cleared) {
                if (cleared == true) {
                  setState(() => _cart.clear());
                  _refreshSelectedChildBalance();
                }
              });
            },
            child: const Text('Ver carrito'),
          ),
        ],
      ),
    );
  }
}
