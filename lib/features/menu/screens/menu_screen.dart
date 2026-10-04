import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../../../core/widgets/custom_header_shape.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/services/auth_service.dart';
import '../../wallet/screens/wallet_recharge_screen.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'orders_screen.dart';

class MenuScreen extends StatefulWidget {
  final int? studentId;

  const MenuScreen({Key? key, this.studentId}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  final Map<int, int> _cart = {}; // itemId -> quantity
  int _selectedCategoryIndex = 0;

  List<Child> _children = [];
  Child? _selectedChild;
  Set<int> _childAllergenIds = {};

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Bar', 'icon': Icons.local_bar},
    {'name': 'Almuerzo', 'icon': Icons.restaurant_menu},
    {'name': 'Snacks', 'icon': Icons.lunch_dining},
    {'name': 'Bebidas', 'icon': Icons.local_drink},
    {'name': 'Postres', 'icon': Icons.icecream},
  ];

  @override
  void initState() {
    super.initState();
    _loadChildrenAndAllergies();
    _fetchMenu();
  }

  Future<void> _loadChildrenAndAllergies() async {
    try {
      final children = await _authService.getChildren();
      if (!mounted || children.isEmpty) return;

      final initial = widget.studentId != null
          ? children.firstWhere(
              (c) => c.id == widget.studentId,
              orElse: () => children.first,
            )
          : children.first;

      setState(() {
        _children = children;
        _selectedChild = initial;
      });
      await _loadChildAllergies(initial.id);
    } catch (_) {
      // Si falla la carga de hijos, seguimos mostrando el menú sin filtro
      // de alérgenos en vez de bloquear toda la pantalla.
    }
  }

  Future<void> _refreshSelectedChildBalance() async {
    try {
      final children = await _authService.getChildren();
      if (!mounted || children.isEmpty) return;
      final updated = children.firstWhere(
        (c) => c.id == _selectedChild?.id,
        orElse: () => children.first,
      );
      setState(() {
        _children = children;
        _selectedChild = updated;
      });
    } catch (_) {
      // Si falla, se queda con el saldo anterior en pantalla.
    }
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
      setState(() => _menuItems = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger500,
        ),
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

  void _openChildSwitcher() {
    if (_children.length <= 1) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '¿Para quién estás pidiendo?',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              ..._children.map((child) {
                final isSelected = child.id == _selectedChild?.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.ink50,
                    backgroundImage: child.profilePictureUrl != null
                        ? NetworkImage(child.profilePictureUrl!)
                        : null,
                    child: child.profilePictureUrl == null
                        ? const Icon(Icons.person, color: AppColors.ink900)
                        : null,
                  ),
                  title: Text(
                    '${child.firstName} ${child.lastName}',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.secondary500,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _switchChild(child);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se vació el carrito al cambiar de hijo.'),
        ),
      );
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedBottomIndex) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletRechargeScreen()),
      ).then((_) => _refreshSelectedChildBalance());
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OrdersScreen(studentId: _selectedChild?.id ?? widget.studentId),
        ),
      );
    }
  }

  // Menu screen is always index 1 in the shared bottom nav.
  int get _selectedBottomIndex => 1;

  @override
  Widget build(BuildContext context) {
    double total = _cart.entries.fold(0, (sum, entry) {
      final item = _menuItems.firstWhere((i) => i.id == entry.key);
      return sum + (item.price * entry.value);
    });

    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomHeaderShape(height: 50),
            _buildHeader(),
            if (_selectedChild != null) _buildChildBanner(),
            _buildCategories(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brand500,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.secondary500,
                      onRefresh: _refreshMenu,
                      child: _buildProductList(),
                    ),
            ),
            if (total > 0) _buildCartSummary(total),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedBottomIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.ink900),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(
                        color: AppColors.teal700.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.teal700,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Menú',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Categorías',
            style: GoogleFonts.nunito(fontSize: 16, color: AppColors.ink900),
          ),
        ],
      ),
    );
  }

  Widget _buildChildBanner() {
    final canSwitch = _children.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: canSwitch ? _openChildSwitcher : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondary50,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                backgroundImage: _selectedChild!.profilePictureUrl != null
                    ? NetworkImage(_selectedChild!.profilePictureUrl!)
                    : null,
                child: _selectedChild!.profilePictureUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.secondary500,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Pidiendo para: ${_selectedChild!.firstName} · \$${(_selectedChild!.balance ?? 0).toStringAsFixed(2)}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary700,
                ),
              ),
              if (canSwitch) ...[
                const SizedBox(width: 6),
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
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategoryIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary500
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary500,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        category['icon'],
                        color: isSelected
                            ? Colors.white
                            : AppColors.secondary500,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
                      style: GoogleFonts.nunito(
                        color: isSelected
                            ? AppColors.ink900
                            : AppColors.ink900.withValues(alpha: 0.5),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductList() {
    final categoryName = _categories[_selectedCategoryIndex]['name'] as String;
    final filteredItems = _menuItems
        .where((item) => item.category == categoryName)
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No hay productos en esta categoría.',
                    style: GoogleFonts.nunito(
                      color: AppColors.ink900.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                ...filteredItems.map((item) => _buildProductCard(item)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(MenuItem item) {
    final isUnsafe = _isUnsafeForChild(item);

    return GestureDetector(
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
      child: Opacity(
        opacity: isUnsafe ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnsafe ? AppColors.danger500 : Colors.grey.shade300,
              width: isUnsafe ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description.isEmpty
                          ? 'Delicioso producto preparado al instante.'
                          : item.description,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF8A8686),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (isUnsafe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚠ Contiene alérgeno',
                          style: GoogleFonts.nunito(
                            color: AppColors.danger700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                          color: AppColors.brand700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 100,
                height: 75, // 100 * 3/4 = 75 → keeps 4:3
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.ink50,
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondary500,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.fastfood,
                            color: Color(0xFF8A8686),
                          ),
                        ),
                      )
                    : const Icon(Icons.fastfood, color: Color(0xFF8A8686)),
              ),
            ],
          ),
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
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
            child: Text(
              'Ver carrito',
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
