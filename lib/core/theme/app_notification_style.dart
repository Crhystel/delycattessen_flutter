import 'package:flutter/material.dart';

import 'app_colors.dart';

enum NotificationType { success, danger, warning, info }

/// Single source of truth for how each notification type looks (header tint,
/// accent color and icon). Used by the floating messenger and by the
/// confirmation dialog so every notification in the app shares one design.
/// To add a new type, add it to [NotificationType] and to [of].
class AppNotificationStyle {
  final Color background;
  final Color accent;
  final IconData icon;

  const AppNotificationStyle({
    required this.background,
    required this.accent,
    required this.icon,
  });

  static const success = AppNotificationStyle(
    background: AppColors.successBg,
    accent: AppColors.success500,
    icon: Icons.check_rounded,
  );

  static const danger = AppNotificationStyle(
    background: AppColors.dangerBg,
    accent: AppColors.danger500,
    icon: Icons.close_rounded,
  );

  static const warning = AppNotificationStyle(
    background: AppColors.warningBg,
    accent: AppColors.warning500,
    icon: Icons.priority_high_rounded,
  );

  static const info = AppNotificationStyle(
    background: AppColors.teal50,
    accent: AppColors.teal500,
    icon: Icons.info_rounded,
  );

  static AppNotificationStyle of(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return success;
      case NotificationType.danger:
        return danger;
      case NotificationType.warning:
        return warning;
      case NotificationType.info:
        return info;
    }
  }
}
