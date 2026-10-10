import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Rounded yellow viewfinder frame with an animated scan line. The concrete
/// scanner (QR or camera feed) goes in [child]. Shared by every scanner screen.
class ScannerFrame extends StatelessWidget {
  final double size;
  final Animation<double> scanAnimation;
  final Widget child;

  const ScannerFrame({
    super.key,
    required this.size,
    required this.scanAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppRadius.lg - 4),
        border: Border.all(color: AppColors.brand500, width: 3),
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
                    color: AppColors.teal500,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal500.withValues(alpha: 0.8),
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

/// Dark help card with a teal accent bar, shown under the viewfinder.
class ScannerNotice extends StatelessWidget {
  final String text;
  final double width;

  const ScannerNotice({super.key, required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.ink900,
        borderRadius: AppRadius.smAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: AppColors.teal500),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
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
