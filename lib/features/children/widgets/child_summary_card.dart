import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/models/auth_models.dart';
import 'child_avatar.dart';

/// Tarjeta de un hijo en la grilla de Inicio: avatar con punto de estado,
/// nombre, "Con saldo / Sin saldo" y saldo. Tocarla abre su ficha.
class ChildSummaryCard extends StatelessWidget {
  const ChildSummaryCard({super.key, required this.child, required this.onTap});

  final Child child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balance = child.balance;
    final isEmpty = balance != null && balance <= 0;
    final stateColor = isEmpty ? AppColors.danger700 : AppColors.success700;

    return Semantics(
      button: true,
      label: 'Ver a ${child.displayName}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChildAvatar(
                    child: child,
                    radius: 24,
                    statusColor: isEmpty
                        ? AppColors.danger500
                        : AppColors.success700,
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.chevron,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                child.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.itemTitle,
              ),
              Text(
                isEmpty ? 'Sin saldo' : 'Con saldo',
                style: AppText.caption.copyWith(color: stateColor),
              ),
              const SizedBox(height: 10),
              Text(
                balance == null ? '—' : '\$${balance.toStringAsFixed(2)}',
                style: AppText.amount.copyWith(
                  color: isEmpty ? AppColors.danger700 : AppColors.ink900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
