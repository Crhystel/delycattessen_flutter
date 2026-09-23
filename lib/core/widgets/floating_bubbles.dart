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

  // Figma reference canvas: 402w x 874h
  static const double _figmaFrameWidth = 402.0;
  static const double _baseBubbleWidth = 144.0;
  static const double _baseBubbleHeight = 123.0;

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
    // Proportional scaling according to Figma 402w frame
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth / _figmaFrameWidth;
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
  }
}
