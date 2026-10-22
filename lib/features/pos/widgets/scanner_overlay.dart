import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Rounded yellow viewfinder frame with an animated scan line. The concrete
/// scanner (QR or camera feed) goes in [child]. Shared by every scanner screen.
class ScannerFrame extends StatelessWidget {
  final double size;
  final Animation<double> scanAnimation;
  final Widget child;

  /// false = solo el borde y la línea, para dibujarlo sobre la cámara a
  /// pantalla completa (tablet).
  final bool filled;

  const ScannerFrame({
    super.key,
    required this.size,
    required this.scanAnimation,
    required this.child,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5A93C),
          width: filled ? 3 : 5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: child),
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, _) {
              return Positioned(
                top: size * scanAnimation.value,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Dark help card with a blue accent bar, shown under the viewfinder.
class ScannerNotice extends StatelessWidget {
  final String text;
  final double width;
  final double? fontSize;

  const ScannerNotice({
    super.key,
    required this.text,
    required this.width,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF03192B),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: const Color(0xFF007ACC)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF007ACC),
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
