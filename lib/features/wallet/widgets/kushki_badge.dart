import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Distintivo "Pago procesado por Kushki". El logo oficial es blanco y menta,
/// por eso va sobre un fondo oscuro.
class KushkiBadge extends StatelessWidget {
  const KushkiBadge({super.key});

  static const String logoAsset = 'assets/images/kushki_logo.svg';
  static const double _logoHeight = 22;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.7),
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.ink900,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Pago procesado por', style: label)),
          SvgPicture.asset(
            logoAsset,
            height: _logoHeight,
            semanticsLabel: 'Kushki',
          ),
        ],
      ),
    );
  }
}
