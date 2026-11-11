import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'floating_bubbles.dart';
import 'subpage_header.dart';

/// Marco de las pantallas de formulario del perfil (Mi perfil, nombres, correo,
/// contraseña): fondo `ink50`, burbujas arriba a la derecha, cabecera
/// [SubpageHeader] con el botón de volver circular y el título, contenido con
/// ancho máximo de página (720) y márgenes de 20, dentro de una columna que se
/// desplaza para que nada se desborde en pantallas pequeñas, en horizontal o con
/// el teclado abierto. Lo usan todos los roles que pueden editar su perfil.
class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  /// Separación entre la cabecera y el primer bloque (el diseño deja 22 en
  /// total, y la cabecera ya trae [AppSpacing.sm] debajo).
  static const double _belowHeader = 14;

  @override
  Widget build(BuildContext context) {
    return _buildDesign(context);
  }

  Widget _buildDesign(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: Stack(
        children: [
          // Las burbujas quedan fijas al borde físico, detrás del contenido.
          const Positioned.fill(
            child: RepaintBoundary(
              child: FloatingBubbles(
                corner: BubbleCorner.topRight,
                design: true,
              ),
            ),
          ),
          ResponsiveCenter(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SubpageHeader(title: title),
                    const SizedBox(height: _belowHeader),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        0,
                        AppSpacing.page,
                        AppSpacing.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
