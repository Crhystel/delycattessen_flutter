import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Esquinas con burbujas. `homeBottomLeft`/`homeBottomRight` son las del
/// inicio de estudiante/docente y del historial (Figma "Frame app Estudiante").
enum BubbleCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  homeBottomLeft,
  homeBottomRight,
}

/// Burbujas decorativas. Con [design] = true dibuja los círculos exactos del
/// rediseño del padre (estáticos, sin animación ni costo por fotograma); sin
/// él conserva las elipses animadas del Figma que usan login, estudiante,
/// docente y caja.
class FloatingBubbles extends StatefulWidget {
  final BubbleCorner corner;
  final bool design;

  const FloatingBubbles({super.key, required this.corner, this.design = false});

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

/// Círculos del rediseño: [top] y [right] (o [bottom]) en dp, tal cual el
/// artboard (390 de ancho), sin escalar: así la distancia al título es la misma
/// en cualquier teléfono.
class _DesignBubbles extends StatelessWidget {
  final BubbleCorner corner;

  const _DesignBubbles({required this.corner});

  Widget _circle(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    final isTop = corner == BubbleCorner.topRight;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isTop) ...[
            Positioned(
              top: -60,
              right: -50,
              child: _circle(AppColors.teal500, 140),
            ),
            Positioned(
              top: -120,
              right: 40,
              child: _circle(AppColors.brand500, 180),
            ),
          ] else ...[
            Positioned(
              bottom: -90,
              right: 60,
              child: _circle(AppColors.teal500, 170),
            ),
            Positioned(
              bottom: -40,
              right: -60,
              child: _circle(AppColors.brand500, 180),
            ),
          ],
        ],
      ),
    );
  }
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  // Figma reference canvas: 402w x 874h
  static const double _figmaFrameWidth = 402.0;
  static const double _baseBubbleWidth = 144.0;
  static const double _baseBubbleHeight = 123.0;
  static const double _maxScale = 1.4;

  @override
  void initState() {
    super.initState();
    // El rediseño es estático: no se crea ningún controlador.
    if (widget.design) return;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Las burbujas de abajo se anclan al borde físico, donde la barra de
  /// navegación de Android (tres botones, transparente en pantalla completa) las
  /// tapaba. Se suben la altura de esa barra y lo que sobresale se recorta, así
  /// se ven igual que en un teléfono sin ella. Se usa `viewPadding` (no
  /// `padding`) para que no se muevan al abrir el teclado.
  Widget _withBottomInset(BuildContext context, Widget bubbles) {
    final isTop =
        widget.corner == BubbleCorner.topLeft ||
        widget.corner == BubbleCorner.topRight;
    if (isTop) return bubbles;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    if (inset <= 0) return bubbles;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ClipRect(child: bubbles),
    );
  }

  Widget _buildBubble({
    required Color color,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(
          Radius.elliptical(width / 2, height / 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (widget.design || controller == null) {
      return _withBottomInset(context, _DesignBubbles(corner: widget.corner));
    }
    // Escala proporcional al frame de 402 del Figma, con tope para que en
    // tablets (800-1280 de ancho) las burbujas no crezcan sin límite.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / _figmaFrameWidth).clamp(0.0, _maxScale);
    final bubbleWidth = _baseBubbleWidth * scale;
    final bubbleHeight = _baseBubbleHeight * scale;

    // Exact Figma coordinates (Figma frame: 402 x 874, Bubble: W 144, H 123):
    // Dorado (0xFFE8A020) sits on top of Azul (0xFF007ACC)
    double? azulLeft, azulRight, azulTop, azulBottom;
    double? doradoLeft, doradoRight, doradoTop, doradoBottom;

    switch (widget.corner) {
      case BubbleCorner.topRight:
        // Figma: Dorado X: 236, Y: -90 | Azul X: 325, Y: -77
        // Offsets from right edge in 402 frame:
        // Dorado right = 402 - (236 + 144) = 22
        // Azul right = 402 - (325 + 144) = -67
        azulRight = -67 * scale;
        azulTop = -77 * scale;
        doradoRight = 22 * scale;
        doradoTop = -90 * scale;
        break;

      case BubbleCorner.topLeft:
        // Figma: Dorado X: 20, Y: -80 | Azul X: -91, Y: -39
        azulLeft = -91 * scale;
        azulTop = -39 * scale;
        doradoLeft = 20 * scale;
        doradoTop = -80 * scale;
        break;

      case BubbleCorner.bottomRight:
        // Figma: Dorado X: 312, Y: 774 | Azul X: 201, Y: 815 (Figma frame 402w x 874h)
        // Dorado: right = 402 - (312 + 144) = -54; bottom = 874 - (774 + 123) = -23
        // Azul: right = 402 - (201 + 144) = 57; bottom = 874 - (815 + 123) = -64
        azulRight = 57 * scale;
        azulBottom = -64 * scale;
        doradoRight = -54 * scale;
        doradoBottom = -23 * scale;
        break;

      case BubbleCorner.bottomLeft:
        azulLeft = 57 * scale;
        azulBottom = -64 * scale;
        doradoLeft = -54 * scale;
        doradoBottom = -23 * scale;
        break;

      case BubbleCorner.homeBottomLeft:
        // Azul pegado al borde izquierdo y dorado encima, más a la derecha.
        azulLeft = -35 * scale;
        azulBottom = -60 * scale;
        doradoLeft = 41 * scale;
        doradoBottom = -92 * scale;
        break;

      case BubbleCorner.homeBottomRight:
        // Azul más bajo y a la izquierda; dorado encima, pegado al borde derecho.
        azulRight = -12 * scale;
        azulBottom = -97 * scale;
        doradoRight = -67 * scale;
        doradoBottom = -60 * scale;
        break;
    }

    final isTop =
        widget.corner == BubbleCorner.topLeft ||
        widget.corner == BubbleCorner.topRight;

    final animated = IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final offset = 6 * (controller.value - 0.5) * (isTop ? 1 : -1);
          return Transform.translate(
            offset: Offset(0, offset),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Azul (underneath)
                Positioned(
                  left: azulLeft,
                  right: azulRight,
                  top: azulTop,
                  bottom: azulBottom,
                  child: _buildBubble(
                    color: AppColors.teal500, // 0xFF007ACC
                    width: bubbleWidth,
                    height: bubbleHeight,
                  ),
                ),
                // 2. Dorado (on top of Azul)
                Positioned(
                  left: doradoLeft,
                  right: doradoRight,
                  top: doradoTop,
                  bottom: doradoBottom,
                  child: _buildBubble(
                    color: AppColors.brand500, // 0xFFE8A020
                    width: bubbleWidth,
                    height: bubbleHeight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return _withBottomInset(context, animated);
  }
}
