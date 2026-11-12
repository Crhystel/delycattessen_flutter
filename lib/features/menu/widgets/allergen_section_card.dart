import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../utils/allergen_advisory.dart';
import 'detail_chip.dart';
import 'detail_section_card.dart';

/// "Alérgenos" card of every detail screen. It is always shown: the item's
/// allergens as red chips, and, when the audience is known, a red box if it has
/// one of them registered or a green one if not. An item without allergens
/// says so.
class AllergenSectionCard extends StatelessWidget {
  final AllergenAdvisory advisory;
  final AllergenSubject subject;

  const AllergenSectionCard({
    super.key,
    required this.advisory,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final hasAllergens = advisory.allergens.isNotEmpty;
    return DetailSectionCard(
      title: 'Alérgenos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAllergens)
            Text('Sin alérgenos registrados', style: AppText.secondaryLg)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final name in advisory.allergens)
                  DetailChip(name, isAllergen: true, design: true),
              ],
            ),
          if (hasAllergens && advisory.showsBoxes) ...[
            const SizedBox(height: AppSpacing.md),
            if (advisory.hasConflict)
              _ConflictBox(advisory: advisory, subject: subject)
            else
              _SafeBox(message: advisory.safeMessage),
          ],
        ],
      ),
    );
  }
}

class _ConflictBox extends StatelessWidget {
  final AllergenAdvisory advisory;
  final AllergenSubject subject;

  const _ConflictBox({required this.advisory, required this.subject});

  @override
  Widget build(BuildContext context) {
    return _NoticeBox(
      background: AppColors.dangerBg,
      crossAxisAlignment: CrossAxisAlignment.start,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            advisory.conflictTitle,
            style: AppText.noteTitle.copyWith(color: AppColors.danger700),
          ),
          const SizedBox(height: 2),
          Text(
            advisory.conflictBody(subject),
            style: AppText.noteBody.copyWith(color: AppColors.danger700),
          ),
        ],
      ),
    );
  }
}

class _SafeBox extends StatelessWidget {
  final String message;

  const _SafeBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return _NoticeBox(
      background: AppColors.successBg,
      crossAxisAlignment: CrossAxisAlignment.center,
      icon: Icons.check_rounded,
      iconColor: AppColors.success700,
      child: Text(
        message,
        style: AppText.noteBody.copyWith(color: AppColors.success700),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final Color background;
  final CrossAxisAlignment crossAxisAlignment;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _NoticeBox({
    required this.background,
    required this.crossAxisAlignment,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.controlAll,
      ),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
