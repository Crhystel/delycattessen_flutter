import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Tint of the icon circle of a [DetailInfoTile].
enum DetailInfoTone {
  purple(AppColors.secondary50, AppColors.secondary500),
  amber(AppColors.warningBg, AppColors.brand700),
  blue(AppColors.teal50, AppColors.teal500);

  const DetailInfoTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Small card with an icon in a tinted circle, a label and a value
/// ("Se sirve el" / "Martes 10 nov").
class DetailInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final DetailInfoTone tone;

  const DetailInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = DetailInfoTone.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.block),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: tone.foreground),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppText.caption),
          const SizedBox(height: 6),
          Text(value, style: AppText.infoValue),
        ],
      ),
    );
  }
}

/// Info tiles in two columns of equal height. Texts wrap, so a large system
/// font makes the tiles taller instead of overflowing.
class DetailInfoGrid extends StatelessWidget {
  final List<DetailInfoTile> tiles;

  const DetailInfoGrid({super.key, required this.tiles});

  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += _columns) {
      if (start > 0) rows.add(const SizedBox(height: AppSpacing.tile));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < _columns; col++) ...[
                if (col > 0) const SizedBox(width: AppSpacing.tile),
                Expanded(
                  child: start + col < tiles.length
                      ? tiles[start + col]
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
