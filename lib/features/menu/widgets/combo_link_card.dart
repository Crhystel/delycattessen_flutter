import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_network_image.dart';
import '../models/menu_models.dart';

/// Amber card that points to a combo ("Promo barata", "Crepes + Tostada",
/// price and saving), used under a product that is part of it.
class ComboLinkCard extends StatelessWidget {
  final Combo combo;
  final VoidCallback onTap;

  const ComboLinkCard({super.key, required this.combo, required this.onTap});

  static const double _photoSize = 64;

  /// "Crepes + Tostada", with "×2" for more than one unit.
  static String summaryOf(Combo combo) => combo.items
      .map((i) => i.quantity > 1 ? '${i.name} ×${i.quantity}' : i.name)
      .join(' + ');

  @override
  Widget build(BuildContext context) {
    final summary = summaryOf(combo);
    return Material(
      color: AppColors.brand50,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(color: AppColors.brandBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.controlAll,
                child: Container(
                  width: _photoSize,
                  height: _photoSize,
                  color: AppColors.ink50,
                  child: AppNetworkImage(
                    url: combo.imageUrl,
                    width: _photoSize,
                    height: _photoSize,
                    error: const Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.brand700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(combo.name, style: AppText.rowTitle),
                    if (summary.isNotEmpty)
                      Text(summary, style: AppText.secondary),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          '\$${combo.price.toStringAsFixed(2)}',
                          style: AppText.price.copyWith(
                            color: AppColors.brand700,
                            fontSize: 16,
                          ),
                        ),
                        if (combo.hasSavings)
                          Text(
                            'Ahorras \$${combo.savings.toStringAsFixed(2)}',
                            style: AppText.caption.copyWith(
                              color: AppColors.success700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brand700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
