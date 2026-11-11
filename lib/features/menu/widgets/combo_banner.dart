import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_network_image.dart';
import '../models/menu_models.dart';

/// Banner ámbar de Inicio con un combo vigente ("COMBO · Hasta el 12 nov").
/// Tocarlo abre el catálogo de productos.
class ComboBanner extends StatelessWidget {
  const ComboBanner({super.key, required this.combo, required this.onTap});

  final Combo combo;
  final VoidCallback onTap;

  static const double _imageSize = 56;

  @override
  Widget build(BuildContext context) {
    final url = combo.imageUrl;
    final until =
        'Hasta el ${combo.endDate.day} ${DateFormatter.shortMonthName(combo.endDate)}';

    return Semantics(
      button: true,
      label: 'Combo ${combo.name}. $until',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.brand50,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.brandBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: _imageSize,
                  height: _imageSize,
                  child: AppNetworkImage(
                    url: url,
                    width: _imageSize,
                    height: _imageSize,
                    error: const _ComboPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand500,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'COMBO',
                            style: AppText.badge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.44,
                            ),
                          ),
                        ),
                        Text(
                          until,
                          style: AppText.caption.copyWith(
                            color: AppColors.brand700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${combo.name} · \$${combo.price.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowTitle.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.brand700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComboPlaceholder extends StatelessWidget {
  const _ComboPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.brand500,
      child: Icon(Icons.local_offer, color: Colors.white),
    );
  }
}
