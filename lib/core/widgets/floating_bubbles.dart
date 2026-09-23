import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BubbleCorner { topLeft, topRight, bottomLeft, bottomRight }

class FloatingBubbles extends StatefulWidget {
  final BubbleCorner corner;

  const FloatingBubbles({
    super.key,
    required this.corner,
  });

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _bubbleWidth = 144.0;
  static const double _bubbleHeight = 123.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBubble({required Color color}) {
    return Container(
      width: _bubbleWidth,
      height: _bubbleHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(
          Radius.elliptical(_bubbleWidth / 2, _bubbleHeight / 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Exact Figma coordinates:
    // Dimensions: W 144, H 123
    // Dorado (0xFFE8A020) sits on top of Azul (0xFF007ACC)
    double? azulLeft, azulRight, azulTop, azulBottom;
    double? doradoLeft, doradoRight, doradoTop, doradoBottom;

    switch (widget.corner) {
      case BubbleCorner.topRight:
        // Figma: Dorado X: 236, Y: -90 | Azul X: 325, Y: -77 (Ref 360w)
        azulRight = -109;
        azulTop = -77;
        doradoRight = -20;
        doradoTop = -90;
        break;

      case BubbleCorner.topLeft:
        // Figma: Dorado X: 20, Y: -80 | Azul X: -91, Y: -39
        azulLeft = -91;
        azulTop = -39;
        doradoLeft = 20;
        doradoTop = -80;
        break;

      case BubbleCorner.bottomRight:
        // Figma: Dorado X: 312, Y: 774 | Azul X: 201, Y: 815 (Ref 360w x 800h)
        azulRight = 15;
        azulBottom = -138;
        doradoRight = -96;
        doradoBottom = -97;
        break;

      case BubbleCorner.bottomLeft:
        azulLeft = 15;
        azulBottom = -138;
        doradoLeft = -96;
        doradoBottom = -97;
        break;
    }

    final isTop = widget.corner == BubbleCorner.topLeft ||
        widget.corner == BubbleCorner.topRight;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final offset = 6 * (_controller.value - 0.5) * (isTop ? 1 : -1);
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
                  child: _buildBubble(color: AppColors.teal500), // 0xFF007ACC
                ),
                // 2. Dorado (on top of Azul)
                Positioned(
                  left: doradoLeft,
                  right: doradoRight,
                  top: doradoTop,
                  bottom: doradoBottom,
                  child: _buildBubble(color: AppColors.brand500), // 0xFFE8A020
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
