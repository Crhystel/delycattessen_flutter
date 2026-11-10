import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'floating_bubbles.dart';
import 'subpage_header.dart';

/// Frame of the form-like pages (profile, edit data): `ink50` background,
/// a light app bar that blends with it, content centered with a maximum width
/// on tablets, and a scrollable column so nothing overflows on small screens,
/// in landscape or with the keyboard open.
///
/// Con [design] = true toma el marco del rediseño del padre: sin barra de
/// aplicación, cabecera [SubpageHeader] con el título, burbujas arriba a la
/// derecha, ancho máximo de página (720) y márgenes de 20. Sin él queda igual
/// que siempre para docente y caja.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.children,
    this.design = false,
  });

  final String title;
  final List<Widget> children;
  final bool design;

  /// Separación entre la cabecera y el primer bloque (el diseño deja 22 en
  /// total, y la cabecera ya trae [AppSpacing.sm] debajo).
  static const double _belowHeader = 14;

  @override
  Widget build(BuildContext context) {
    if (design) return _buildDesign(context);
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppTheme.lightAppBar(
        title: Text(title),
        backgroundColor: AppColors.ink50,
      ),
      body: ResponsiveCenter(
        maxWidth: AppLayout.formMaxWidth,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
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
