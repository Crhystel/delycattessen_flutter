import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/menu_models.dart';

class DishDetailScreen extends StatefulWidget {
  final MenuDish dish;
  final Function(int) onAdd;

  const DishDetailScreen({
    super.key,
    required this.dish,
    required this.onAdd,
  });

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dish = widget.dish;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 280,
                color: AppColors.ink50,
                child: dish.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: dish.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 900,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary500,
                          ),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.fastfood,
                          size: 100,
                          color: AppColors.secondary500,
                        ),
                      )
                    : const Icon(
                        Icons.fastfood,
                        size: 100,
                        color: AppColors.secondary500,
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: AppColors.ink900,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          dish.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '\$${dish.price.toStringAsFixed(2)}',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand700,
                        ),
                      ),
                    ],
                  ),
                  if (dish.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      dish.description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink900.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (dish.allergens.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Alérgenos identificados'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: dish.allergens
                          .map((a) => _buildChip(a, isAllergen: true))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildChip(String label, {bool isAllergen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAllergen ? AppColors.dangerBg : AppColors.secondary50,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAllergen ? AppColors.danger700 : AppColors.secondary700,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary500),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: AppColors.secondary500),
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.secondary500),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: PrimaryButton(
                label:
                    'Añadir \$${(widget.dish.price * _quantity).toStringAsFixed(2)}',
                onPressed: () {
                  widget.onAdd(_quantity);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
