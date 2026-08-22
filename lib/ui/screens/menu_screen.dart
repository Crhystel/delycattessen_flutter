import 'package:flutter/material.dart';
import '../../data/models/menu_models.dart';
import '../../data/services/menu_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_header_shape.dart';
import '../widgets/custom_bottom_nav.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final int studentId;

  const MenuScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  final Map<int, int> _cart = {}; // itemId -> quantity
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'icon': Icons.restaurant_menu},
    {'name': 'Snacks', 'icon': Icons.lunch_dining},
    {'name': 'Bebidas', 'icon': Icons.local_drink},
    {'name': 'Postres', 'icon': Icons.icecream},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      final items = await _menuService.getMenu();
      setState(() => _menuItems = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    double total = _cart.entries.fold(0, (sum, entry) {
      final item = _menuItems.firstWhere((i) => i.id == entry.key);
      return sum + (item.price * entry.value);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomHeaderShape(height: 50),
            _buildHeader(),
            _buildCategories(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                  : _buildProductList(),
            ),
            if (total > 0) _buildCartSummary(total),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
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
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueChip,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(color: AppColors.primaryBlue.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Menú',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Categorías',
            style: TextStyle(fontSize: 16, color: AppColors.textDark),
          ),
        ],
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
                        color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryPurple,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        category['icon'],
                        color: isSelected ? AppColors.white : AppColors.primaryPurple,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
                      style: TextStyle(
                        color: isSelected ? AppColors.textDark : AppColors.textGray,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _categories[_selectedCategoryIndex]['name'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._menuItems.map((item) => _buildProductCard(item)).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(MenuItem item) {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    item.description.isEmpty ? 'Delicioso producto preparado al instante.' : item.description,
                    style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
                // image: DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover),
              ),
              child: const Icon(Icons.fastfood, color: AppColors.textGray),
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
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    studentId: widget.studentId,
                    cart: _cart,
                    menuItems: _menuItems,
                  ),
                ),
              ).then((cleared) {
                if (cleared == true) setState(() => _cart.clear());
              });
            },
            child: const Text('Ver carrito', style: TextStyle(color: AppColors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
