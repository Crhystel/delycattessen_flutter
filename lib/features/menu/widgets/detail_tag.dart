import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text.dart';

/// Pill over the photo of a detail screen, at the top right: the category or
/// "Menú del mes" (white), or "COMBO" (amber).
class DetailTag extends StatelessWidget {
  final String label;
  final bool _combo;

  const DetailTag.neutral(this.label, {super.key}) : _combo = false;

  const DetailTag.combo({super.key}) : label = 'COMBO', _combo = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: _combo ? 5 : 6),
      decoration: BoxDecoration(
        color: _combo ? AppColors.brand500 : Colors.white,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _combo
            ? AppText.tag.copyWith(
                color: AppColors.ink900,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              )
            : AppText.tag,
      ),
    );
  }
}
