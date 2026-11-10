import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Shared bottom sheet: white surface with large top radius, drag handle,
/// optional title/subtitle and safe-area padding. Use it instead of calling
/// `showModalBottomSheet` directly so every sheet looks the same.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? subtitle,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool design = false,
    bool showCloseButton = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      // El rediseño oscurece el fondo con un violeta grisáceo en vez de negro.
      barrierColor: design ? AppColors.sheetScrim.withValues(alpha: 0.6) : null,
      // En tablet la hoja queda centrada con ancho de formulario.
      constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                design ? AppSpacing.page : AppSpacing.xl,
                design ? 10 : AppSpacing.md,
                design ? AppSpacing.page : AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: design ? 40 : 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: design
                            ? AppColors.sheetHandle
                            : AppColors.ink900.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (title != null || showCloseButton) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Text(
                                  title,
                                  style: design
                                      ? textTheme.titleLarge?.copyWith(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                        )
                                      : textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                ),
                              if (subtitle != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle,
                                  style: design
                                      ? textTheme.bodyMedium?.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.muted,
                                        )
                                      : textTheme.bodyMedium?.copyWith(
                                          color: AppColors.ink900.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showCloseButton)
                          Semantics(
                            button: true,
                            label: 'Cerrar',
                            child: GestureDetector(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.ink50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 22,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink900.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Flexible(child: builder(sheetContext)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
