import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/screens/student_registration_screen.dart';
import '../providers/children_provider.dart';
import '../screens/edit_child_screen.dart';
import 'child_avatar.dart';

/// Sección "Mis hijos" de "Mi perfil" del padre: cada hijo abre sus datos y,
/// al final, "Añadir hijo/a". Se inyecta en `ProfileScreen` desde el
/// `ParentShell` (auth no importa de children).
class ProfileChildrenSection extends StatelessWidget {
  const ProfileChildrenSection({super.key});

  Future<void> _edit(BuildContext context, Child child) async {
    final provider = context.read<ChildrenProvider>();
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(builder: (_) => EditChildScreen(child: child)),
    );
    // La pantalla de datos devuelve algo solo si se guardó un cambio.
    if (result == null || result == false) return;
    provider.refresh();
  }

  Future<void> _add(BuildContext context) async {
    final provider = context.read<ChildrenProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
    );
    // El registro no dice si creó a alguien; `refresh` comparte la petición
    // en curso, así que pedirlo de más no duplica llamadas.
    provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final children = context.watch<ChildrenProvider>().children;
    return FormSectionCard(
      design: true,
      title: 'Mis hijos',
      contentPadding: EdgeInsets.zero,
      children: [
        for (final child in children) ...[
          _ChildRow(child: child, onTap: () => _edit(context, child)),
          const Divider(height: 1, color: AppColors.divider),
        ],
        _AddChildRow(onTap: () => _add(context)),
      ],
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.child, required this.onTap});

  final Child child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            ChildAvatar(child: child, radius: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.rowTitle,
                  ),
                  if (child.institutionName.isNotEmpty)
                    Text(
                      child.institutionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.secondaryLg,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

/// "Añadir hijo/a": círculo de 40 con borde discontinuo morado y texto morado.
class _AddChildRow extends StatelessWidget {
  const _AddChildRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const DashedBorder(
              radius: 20,
              dashLength: 5,
              gap: 4,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.add, size: 18, color: AppColors.secondary500),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Añadir hijo/a',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowTitle.copyWith(color: AppColors.secondary500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
