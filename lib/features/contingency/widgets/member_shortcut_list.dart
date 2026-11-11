import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

/// Un acceso directo del inicio de estudiantes y docentes.
class MemberShortcut {
  const MemberShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Tarjetas de acceso directo, una bajo otra. Qué accesos hay según el rol lo
/// decide quien la usa; este widget solo los pinta.
class MemberShortcutList extends StatelessWidget {
  const MemberShortcutList({super.key, required this.shortcuts});

  final List<MemberShortcut> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < shortcuts.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _ShortcutCard(shortcut: shortcuts[i]),
        ],
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcut});

  final MemberShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: shortcut.onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(shortcut.icon, color: AppColors.secondary500),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              shortcut.label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
