import 'package:flutter/material.dart';
import '../models/menu_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_header_shape.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final MenuItem item;
  final Function(int) onAdd;

  const ProductDetailScreen({Key? key, required this.item, required this.onAdd})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomHeaderShape(height: 50),
                // Pseudo image container (as per Figma big burger image)
                Container(
                  width: double.infinity,
                  height: 250,
                  color: AppColors.ink50,
                  child: widget.item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.item.imageUrl!,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.secondary500,
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.fastfood,
                            size: 100,
                            color: Color(0xFF8A8686),
                          ),
                        )
                      : const Icon(
                          Icons.fastfood,
                          size: 100,
                          color: Color(0xFF8A8686),
                        ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.item.description.isEmpty
                              ? 'Carne a la parrilla, Queso, Lechuga, Tomate'
                              : widget.item.description,
                          style: const TextStyle(
                            color: Color(0xFF8A8686),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '\$${widget.item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Ingredientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                                                      children: widget.menuItem.ingredients
                                .map((ingredient) => _buildIngredientChip(ingredient.name))
                                .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.ink900),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.teal700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: AppColors.ink900),
                  onPressed: () {
                    if (_quantity > 1) setState(() => _quantity--);
                  },
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.ink900),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () {
              widget.onAdd(_quantity);
              Navigator.pop(context);
            },
            child: Text(
              'Añadir \$${(widget.item.price * _quantity).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
