import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// White card with a title ("Alérgenos", "Incluye"). With [padded] false the
/// content goes edge to edge (lists with their own rows) and only the title is
/// padded.
class DetailSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool padded;

  const DetailSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.padded = true,
  });

  @override
  Widget build(BuildContext context) {
    final heading = Text(title, style: AppText.cardTitle);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: padded
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: AppSpacing.md),
                  child,
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: heading,
                ),
                child,
              ],
            ),
    );
  }
}
