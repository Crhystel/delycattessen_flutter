import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_network_image.dart';
import '../models/menu_models.dart';
import 'detail_section_heading.dart';

/// "Otros combos": the other combos in two columns (photo, name and price).
/// Draws nothing when [combos] is empty.
class OtherCombosGrid extends StatelessWidget {
  final List<Combo> combos;
  final ValueChanged<Combo> onComboTap;

  const OtherCombosGrid({
    super.key,
    required this.combos,
    required this.onComboTap,
  });

  static const int _columns = 2;
  static const double _photoHeight = 96;

  @override
  Widget build(BuildContext context) {
    if (combos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DetailSectionHeading('Otros combos'),
        const SizedBox(height: AppSpacing.tile),
        // The photo needs a fixed width inside IntrinsicHeight (see
        // AppNetworkImage), so the tile width is measured here.
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth =
                (constraints.maxWidth - AppSpacing.tile * (_columns - 1)) /
                _columns;
            return _rows(tileWidth);
          },
        ),
      ],
    );
  }

  Widget _rows(double tileWidth) {
    final rows = <Widget>[];
    for (var start = 0; start < combos.length; start += _columns) {
      if (start > 0) rows.add(const SizedBox(height: AppSpacing.tile));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < _columns; col++) ...[
                if (col > 0) const SizedBox(width: AppSpacing.tile),
                Expanded(
                  child: start + col < combos.length
                      ? _Tile(
                          combo: combos[start + col],
                          width: tileWidth,
                          onTap: () => onComboTap(combos[start + col]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _Tile extends StatelessWidget {
  final Combo combo;
  final double width;
  final VoidCallback onTap;

  const _Tile({required this.combo, required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: OtherCombosGrid._photoHeight,
              color: AppColors.ink50,
              child: AppNetworkImage(
                url: combo.imageUrl,
                width: width,
                height: OtherCombosGrid._photoHeight,
                error: const Icon(
                  Icons.local_offer_rounded,
                  color: AppColors.brand700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    combo.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.rowTitle.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${combo.price.toStringAsFixed(2)}',
                    style: AppText.price.copyWith(
                      color: AppColors.brand700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
