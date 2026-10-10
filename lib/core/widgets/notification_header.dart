import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Decorative header shared by every notification (toast and dialog): a soft
/// tinted background with floating brand-color circles and a white badge
/// holding the status icon. It does not clip itself; wrap it in a
/// [ClipRRect] with the card's top radius.
class NotificationHeader extends StatelessWidget {
  final Color background;
  final Color accent;
  final IconData icon;
  final double height;

  const NotificationHeader({
    super.key,
    required this.background,
    required this.accent,
    required this.icon,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: background,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: -26,
            top: -26,
            child: _FloatingCircle(76, AppColors.brand500, 0.55),
          ),
          const Positioned(
            right: -16,
            top: -6,
            child: _FloatingCircle(50, AppColors.teal500, 0.55),
          ),
          const Positioned(
            right: 16,
            bottom: -26,
            child: _FloatingCircle(60, AppColors.secondary500, 0.5),
          ),
          const Positioned(
            left: 36,
            bottom: -18,
            child: _FloatingCircle(32, AppColors.teal500, 0.4),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _FloatingCircle(this.size, this.color, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}
