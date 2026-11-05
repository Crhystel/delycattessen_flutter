import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Small rounded label of a detail screen: an ingredient (purple) or an
/// allergen (red).
class DetailChip extends StatelessWidget {
  final String label;
  final bool isAllergen;

  const DetailChip(this.label, {super.key, this.isAllergen = false});

  @override
  Widget build(BuildContext context) {
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
}
