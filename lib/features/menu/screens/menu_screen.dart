import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_header_shape.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../models/menu_models.dart';
import '../services/menu_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
            _buildCategories(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brand500,
                      ),
                    )
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
    return ListView(
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
                _categories[_selectedCategoryIndex]['name'],
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
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
              height: 75, // 100 * 3/4 = 75 → mantiene 4:3
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
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary500,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
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
                    studentId: widget.studentId,
                    cart: _cart,
                    menuItems: _menuItems,
                  ),
                ),
              ).then((cleared) {
                if (cleared == true) setState(() => _cart.clear());
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
