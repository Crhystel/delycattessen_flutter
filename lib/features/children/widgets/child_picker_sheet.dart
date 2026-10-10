import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/child_avatar_chip.dart';
import '../providers/children_provider.dart';

/// Bottom sheet to pick which child is the shared "selected child".
/// Used by every screen that lets the parent switch child.
class ChildPickerSheet {
  ChildPickerSheet._();

  static Future<void> show(
    BuildContext context,
    ChildrenProvider provider, {
    String title = '¿Para quién es?',
  }) {
    return AppBottomSheet.show<void>(
      context,
      title: title,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: provider.children.map((child) {
          final isSelected = child.id == provider.selectedChild?.id;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ChildAvatarChip(
              imageUrl: child.profilePictureUrl,
              radius: 18,
            ),
            title: Text(
              '${child.firstName} ${child.lastName}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.teal500)
                : null,
            onTap: () {
              Navigator.pop(sheetContext);
              provider.select(child.id);
            },
          );
        }).toList(),
      ),
    );
  }
}
