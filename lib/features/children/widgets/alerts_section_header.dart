import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Título de la sección de avisos de Inicio: campana roja, "Avisos" y una
/// insignia roja con cuántos avisos hay. La insignia es un círculo con un
/// dígito y una píldora con más.
class AlertsSectionHeader extends StatelessWidget {
  const AlertsSectionHeader({super.key, required this.count});

  final int count;

  static const double _iconSize = 22;
  static const double _badgeMinSize = 22;
  static const double _badgeFontSize = 12.5;
  static const double _badgeHorizontalPadding = 6;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Avisos, $count',
      excludeSemantics: true,
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.notifications_none_rounded,
              size: _iconSize,
              color: AppColors.danger500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Avisos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sectionTitle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ExcludeSemantics(
            child: Container(
              key: const ValueKey('alerts-count-badge'),
              constraints: const BoxConstraints(
                minWidth: _badgeMinSize,
                minHeight: _badgeMinSize,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: _badgeHorizontalPadding,
              ),
              decoration: const BoxDecoration(
                color: AppColors.danger500,
                borderRadius: AppRadius.fullAll,
              ),
              // Wraps the number (factor 1) so the badge does not stretch to
              // the height of the row; the minimum size makes it a circle.
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  '$count',
                  maxLines: 1,
                  style: AppText.sectionTitle.copyWith(
                    fontSize: _badgeFontSize,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
