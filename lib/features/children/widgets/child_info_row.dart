import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Fila de "Su día" en la ficha del hijo: icono cuadrado (radio 12), título,
/// contenido libre debajo ([child]) y flecha. El color del icono cambia según
/// la fila (morado para el límite, rojo para las alergias).
class ChildInfoRow extends StatelessWidget {
  const ChildInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
    this.iconBackground = AppColors.secondary50,
    this.iconColor = AppColors.secondary500,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget child;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.rowTitle),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

/// Chip rojo con el nombre de una alergia (12.5/700).
class AllergyPill extends StatelessWidget {
  const AllergyPill({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        name,
        style: AppText.badge.copyWith(
          fontSize: 12.5,
          color: AppColors.danger700,
        ),
      ),
    );
  }
}
