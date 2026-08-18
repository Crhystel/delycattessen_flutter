import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BubbleCorner { topLeft, topRight, bottomLeft, bottomRight }

///
/// Uso: colócalo dentro de un Stack, antes del contenido principal.
///   Stack(children: [FloatingBubbles(corner: BubbleCorner.topRight), ...contenido])
class FloatingBubbles extends StatefulWidget {
  final BubbleCorner corner;
  final double largeSize;
  final double smallSize;
  final double containerSize;

  const FloatingBubbles({
    super.key,
    required this.corner,
    this.largeSize = 220,
    this.smallSize = 190,
    this.containerSize = 300,
  });

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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

  bool get _isTop =>
      widget.corner == BubbleCorner.topLeft ||
      widget.corner == BubbleCorner.topRight;
  bool get _isLeft =>
      widget.corner == BubbleCorner.topLeft ||
      widget.corner == BubbleCorner.bottomLeft;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _isTop ? -100 : null,
      bottom: _isTop ? null : -100,
      left: _isLeft ? -70 : null,
      right: _isLeft ? null : -70,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = 14 * (_controller.value - 0.5) * (_isTop ? 1 : -1);
          return Transform.translate(offset: Offset(0, offset), child: child);
        },
        child: SizedBox(
          width: widget.containerSize,
          height: widget.containerSize,
          child: Stack(
            children: [
              Positioned(
                left: _isLeft ? 0 : null,
                right: _isLeft ? null : 0,
                top: _isTop ? 0 : null,
                bottom: _isTop ? null : 0,
                child: Container(
                  width: widget.largeSize,
                  height: widget.largeSize,
                  decoration: const BoxDecoration(
                    color: AppColors.teal700,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: _isLeft ? widget.largeSize / 2 : null,
                right: _isLeft ? null : widget.largeSize / 2,
                top: _isTop ? 0 : null,
                bottom: _isTop ? null : 0,
                child: Container(
                  width: widget.smallSize,
                  height: widget.smallSize,
                  decoration: const BoxDecoration(
                    color: AppColors.brand500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
