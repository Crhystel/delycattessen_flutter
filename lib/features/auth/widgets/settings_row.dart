import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// One option of a settings list: icon, title, current value and an arrow on
/// the right that tells the user it opens its own screen. Text is cut with an
/// ellipsis, so a long value never overflows the row.
///
/// Con [design] = true usa el estilo del rediseño del padre (título 15.5/700,
/// detalle 13.5/600 en `muted`, flecha `chevron` de 18).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.design = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool design;

  static const double _minHeight = 64;
  static const double _iconCircle = 40;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = subtitle;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: _iconCircle,
                height: _iconCircle,
                decoration: const BoxDecoration(
                  color: AppColors.secondary50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.secondary500,
                  size: design ? 19 : 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: design ? 15.5 : null,
                        fontWeight: design ? FontWeight.w700 : FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    if (detail != null && detail.isNotEmpty)
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: design
                            ? textTheme.bodySmall?.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              )
                            : textTheme.bodySmall?.copyWith(
                                color: AppColors.ink900.withValues(alpha: 0.6),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                size: design ? 20 : 24,
                color: design
                    ? AppColors.chevron
                    : AppColors.ink900.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [rows] with a thin divider between them. Con [design] usa el divisor más
/// suave del rediseño.
List<Widget> withDividers(List<Widget> rows, {bool design = false}) => [
  for (var i = 0; i < rows.length; i++) ...[
    if (i > 0)
      Divider(
        height: 1,
        color: design ? AppColors.divider : AppColors.teal50,
      ),
    rows[i],
  ],
];
