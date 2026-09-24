import 'package:flutter/material.dart';
import 'app_notification_messenger.dart';

export 'app_notification_messenger.dart';

/// Compatibilidad hacia atrás: Redirige llamadas heredadas de
/// AppNotificationDialog hacia el nuevo patrón estándar de ScaffoldMessenger.
class AppNotificationDialog {
  AppNotificationDialog._();

  static Future<void> show(
    BuildContext context, {
    required NotificationType type,
    required String title,
    required String message,
    String? highlightValue,
    String? highlightCaption,
    String primaryButtonLabel = 'Aceptar',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
    IconData? icon,
  }) async {
    final fullMessage = highlightValue != null
        ? '$message ($highlightValue)'
        : message;

    AppNotificationMessenger.show(
      context,
      type: type,
      title: title,
      message: fullMessage,
      icon: icon,
      actionLabel: onPrimaryPressed != null && primaryButtonLabel != 'Aceptar'
          ? primaryButtonLabel
          : null,
      onAction: onPrimaryPressed,
    );
  }
}
