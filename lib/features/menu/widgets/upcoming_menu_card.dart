import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../models/menu_models.dart';
import '../utils/upcoming_menu_labels.dart';

/// Tarjeta de Inicio con el primer platillo del próximo día del menú y el
/// botón "Preordenar". Tocarla o el botón abre ese día en la pestaña Menú.
class UpcomingMenuCard extends StatelessWidget {
  const UpcomingMenuCard({
    super.key,
    required this.dish,
    required this.date,
    required this.onOrder,
    this.now,
  });

  final MenuDish dish;
  final DateTime date;
  final VoidCallback onOrder;

  /// "Hoy" para armar la línea de fecha; por defecto, el reloj del dispositivo.
  final DateTime? now;

  static const double _imageSize = 92;

  @override
  Widget build(BuildContext context) {
    final url = dish.imageUrl;
    final cache = AppImageCacheHelper.cacheSize(context, _imageSize);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: _imageSize,
              height: _imageSize,
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      memCacheWidth: cache,
                      memCacheHeight: cache,
                      errorWidget: (_, _, _) => const _DishPlaceholder(),
                    )
                  : const _DishPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  UpcomingMenuLabels.dateLine(date, now ?? DateTime.now()),
                  style: AppText.secondary,
                ),
                const SizedBox(height: 6),
                // Wrap: with a large system font the button goes to the next
                // line instead of overflowing.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      '\$${dish.price.toStringAsFixed(2)}',
                      style: AppText.price.copyWith(color: AppColors.brand700),
                    ),
                    FilledButton(
                      onPressed: onOrder,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary500,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: AppText.button.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Preordenar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DishPlaceholder extends StatelessWidget {
  const _DishPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.ink50,
      child: Icon(Icons.fastfood, color: AppColors.secondary500),
    );
  }
}
