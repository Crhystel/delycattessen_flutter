import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_notification_style.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'notification_header.dart';

/// Modal dialog strictly used for user action confirmation (e.g. Logout, Cancel).
///
/// Shares its look with the floating notifications (same header, radius and
/// typography). A destructive confirmation (the default) uses the danger
/// style and a red button; otherwise it uses the info style and the yellow
/// primary-action button.
class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = true,
    this.icon,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = true,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = AppNotificationStyle.of(
      isDestructive ? NotificationType.danger : NotificationType.info,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NotificationHeader(
                background: style.background,
                accent: style.accent,
                icon: icon ?? style.icon,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.teal700,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(
                                color: AppColors.teal500,
                                width: 1.5,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.smAll,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              cancelLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.smAll,
                              ),
                              elevation: 0,
                              backgroundColor: isDestructive
                                  ? AppColors.danger500
                                  : AppColors.brand500,
                              foregroundColor: isDestructive
                                  ? Colors.white
                                  : AppColors.ink900,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
