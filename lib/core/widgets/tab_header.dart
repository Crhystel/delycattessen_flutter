import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_spacing.dart';
import 'profile_bubble.dart';

/// Cabecera de las pestañas y del inicio: el título (o saludo) a la izquierda y
/// la burbuja de perfil a la derecha.
///
/// La burbuja queda SIEMPRE anclada arriba, a [AppLayout.pageTopPadding] del
/// borde de la pantalla, sin importar cuánto texto lleve el lado izquierdo (un
/// subtítulo, un saludo de dos líneas o letra grande del sistema). Antes cada
/// pestaña centraba la burbuja con su texto y por eso quedaba a distinta altura.
/// El texto se centra con la burbuja cuando mide menos que ella (un título de
/// una línea) y, si es más alto, crece hacia abajo sin mover la burbuja.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.leading,
    this.trailing,
    this.topPadding,
    this.horizontalPadding = AppSpacing.page,
  });

  /// Margen lateral; las pantallas de inicio en tablet usan [AppSpacing.pageWide].
  final double horizontalPadding;

  /// Título, saludo o subtítulos (normalmente una `Column`).
  final Widget leading;

  /// Burbuja de perfil u otra acción de la derecha.
  final Widget? trailing;

  /// Margen sobre la cabecera. Por defecto [AppLayout.pageTopPadding] (zona de
  /// la barra de estado más 16). Lo cambia solo quien ya suma la zona de la
  /// barra de estado por su cuenta (`CollapsingHeader.topInset` en Menú y
  /// Productos) y pasa aquí el margen fijo restante.
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding ?? AppLayout.pageTopPadding(context),
        horizontalPadding,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ProfileBubble.extent,
              ),
              child: Align(alignment: Alignment.centerLeft, child: leading),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
