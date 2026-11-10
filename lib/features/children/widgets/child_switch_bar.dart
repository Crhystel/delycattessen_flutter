import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/screens/student_registration_screen.dart';
import '../providers/children_provider.dart';
import 'child_avatar.dart';
import 'child_picker_sheet.dart';

/// Barra "Pidiendo para / Recargar a / Pedidos de ..." que muestra al hijo
/// seleccionado global y, si hay más de uno, abre la hoja para cambiarlo.
/// Con [showBalance] muestra su saldo; si no, el texto "Cambiar".
class ChildSwitchBar extends StatelessWidget {
  const ChildSwitchBar({
    super.key,
    required this.label,
    this.showBalance = false,
    this.sheetTitle = '¿Para quién?',
  });

  final String label;
  final bool showBalance;
  final String sheetTitle;

  Future<void> _addChild(BuildContext context) async {
    final provider = context.read<ChildrenProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
    );
    provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildrenProvider>();
    final child = provider.selectedChild;
    if (child == null) return const SizedBox.shrink();
    final canSwitch = provider.children.length > 1;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: canSwitch,
      label: canSwitch
          ? 'Cambiar hijo. $label ${child.displayName}'
          : '$label ${child.displayName}',
      child: InkWell(
        onTap: canSwitch
            ? () => ChildPickerSheet.show(
                context,
                provider,
                title: sheetTitle,
                onAddChild: () => _addChild(context),
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lineStrong),
          ),
          child: Row(
            children: [
              ChildAvatar(child: child, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.caption),
                    Text(
                      child.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.itemTitle,
                    ),
                  ],
                ),
              ),
              if (showBalance && child.balance != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '\$${child.balance!.toStringAsFixed(2)}',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.brand700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ] else if (canSwitch)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'Cambiar',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.secondary500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (canSwitch)
                const Icon(
                  Icons.expand_more,
                  color: AppColors.secondary500,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
