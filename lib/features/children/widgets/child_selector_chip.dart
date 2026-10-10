import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../providers/children_provider.dart';
import 'child_picker_sheet.dart';

/// Chip "Para: [avatar] Nombre ▾" que muestra al hijo seleccionado global y,
/// si hay más de uno, permite cambiarlo con un toque.
class ChildSelectorChip extends StatelessWidget {
  final String label;

  const ChildSelectorChip({super.key, this.label = 'Mostrando a'});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildrenProvider>();
    final child = provider.selectedChild;
    if (child == null) return const SizedBox.shrink();
    final canSwitch = provider.children.length > 1;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: canSwitch
            ? () => ChildPickerSheet.show(
                context,
                provider,
                title: '¿De quién quieres ver la información?',
              )
            : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: AppColors.secondary50,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChildAvatarChip(imageUrl: child.profilePictureUrl, radius: 12),
              const SizedBox(width: 8),
              Text(
                '$label ${child.firstName}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary700,
                ),
              ),
              if (canSwitch) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more,
                  size: 18,
                  color: AppColors.secondary700,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
