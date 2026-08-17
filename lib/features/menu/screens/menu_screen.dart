import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/menu_item.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  MenuCategory _selectedCategory = MenuCategory.general;
  final _searchController = TextEditingController();

  static const _categoryLabels = {
    MenuCategory.general: 'General',
    MenuCategory.snacks: 'Snacks',
    MenuCategory.bebidas: 'Bebidas',
  };

  static const _categoryIcons = {
    MenuCategory.general: Icons.restaurant,
    MenuCategory.snacks: Icons.lunch_dining,
    MenuCategory.bebidas: Icons.local_cafe,
  };

  @override
  Widget build(BuildContext context) {
    final items = mockMenuItems
        .where((i) => i.category == _selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Menú',
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Categorías',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    Text(
                      _categoryLabels[_selectedCategory]!,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(_buildItemCard),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.ink900),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: GoogleFonts.nunito(
                  color: AppColors.ink900.withValues(alpha: 0.4),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.secondary500,
                ),
                filled: true,
                fillColor: AppColors.ink50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Row(
      children: MenuCategory.values.map((category) {
        final isSelected = category == _selectedCategory;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary500
                        : AppColors.secondary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _categoryIcons[category],
                    color: isSelected ? Colors.white : AppColors.secondary500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _categoryLabels[category]!,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.secondary700
                        : AppColors.ink900.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.ink900.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '\$${item.price.toStringAsFixed(2)}',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.brand700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: AppColors.brand500,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const Icon(Icons.restaurant_menu, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
