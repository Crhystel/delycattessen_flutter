import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Standard white card used across parent screens. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;

  /// Estilo del rediseño del padre: radio 22 y borde fino `AppColors.line`.
  /// Sin él la tarjeta queda como antes (radio 20, borde `teal50`) para las
  /// pantallas de estudiante, docente y caja.
  final bool design;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.color = Colors.white,
    this.design = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = design ? AppRadius.cardAll : AppRadius.mdAll;
    return Padding(
      padding: margin,
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: design ? AppColors.line : AppColors.teal50,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
