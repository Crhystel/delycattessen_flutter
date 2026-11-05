import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// A themed group of form fields: a small grey title over a white card.
/// Meant for pages on the `ink50` background, so each topic reads as its own
/// block. The card takes the width the page gives it.
class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.contentPadding,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Padding inside the card; zero lets rows (e.g. a settings list) reach the
  /// card edges. Defaults to the standard card padding.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink900.withValues(alpha: 0.6),
            ),
          ),
        ),
        AppCard(
          padding: contentPadding ?? const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.ink900.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}
