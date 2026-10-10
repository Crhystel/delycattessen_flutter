import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/floating_bubbles.dart';

/// Shared frame for the auth screens (login, parent register, forced password
/// change): decorative bubbles, a yellow icon badge, title/subtitle and the
/// blue form card. Screens only provide the fields ([children]) and anything
/// shown below the card ([footer]).
class AuthFormLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> footer;

  const AuthFormLayout({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: Stack(
        children: [
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.topLeft),
          ),
          const RepaintBoundary(
            child: FloatingBubbles(corner: BubbleCorner.bottomRight),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.brand500,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 44, color: AppColors.ink900),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink900.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: const BoxDecoration(
                        color: AppColors.teal500,
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Column(children: children),
                    ),
                    ...footer,
                    const SizedBox(height: AppSpacing.xxl),
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
