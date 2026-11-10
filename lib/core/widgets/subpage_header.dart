import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Cabecera de las subpantallas del padre según el diseño: botón de volver
/// circular (blanco, con borde), título de 25 a la izquierda y, si se da,
/// subtítulo (por ejemplo el nombre del hijo) y una acción a la derecha.
///
/// Respeta el área segura superior para que la distancia entre el borde de la
/// pantalla y el título sea la misma en cualquier dispositivo.
class SubpageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onBack;

  /// Sin botón de volver (por ejemplo cuando la pantalla es una pestaña).
  final bool showBack;

  const SubpageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppLayout.pageTopPadding(context),
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            SubpageBackButton(onPressed: onBack),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.pageTitle,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.secondaryLg,
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Botón circular de volver (44, blanco, borde fino) del diseño.
class SubpageBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  /// Fondo translúcido para cabeceras de color (la ficha del hijo).
  final bool onColor;

  const SubpageBackButton({super.key, this.onPressed, this.onColor = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onColor
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white,
            border: onColor ? null : Border.all(color: AppColors.lineStrong),
          ),
          child: Icon(
            Icons.arrow_back,
            size: 22,
            color: onColor ? Colors.white : AppColors.ink900,
          ),
        ),
      ),
    );
  }
}
