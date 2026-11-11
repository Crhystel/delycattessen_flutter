import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Small rounded label of a detail screen: an ingredient (purple) or an
/// allergen (red). With [design] it is the pill of the detail redesign
/// (bigger text, fully rounded).
class DetailChip extends StatelessWidget {
  final String label;
  final bool isAllergen;
  final bool design;

  const DetailChip(
    this.label, {
    super.key,
    this.isAllergen = false,
    this.design = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: design ? 14 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAllergen ? AppColors.dangerBg : AppColors.secondary50,
        borderRadius: design ? AppRadius.fullAll : AppRadius.smAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAllergen ? AppColors.danger700 : AppColors.secondary700,
          fontWeight: FontWeight.w700,
          fontSize: design ? 14 : 12,
        ),
      ),
    );
  }
}
