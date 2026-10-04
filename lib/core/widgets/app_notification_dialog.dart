import 'package:flutter/material.dart';
import 'app_notification_messenger.dart';

export 'app_notification_messenger.dart';

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
    Duration? duration,
  }) async {
    final fullMessage = highlightValue != null
        ? '$message ($highlightValue)'
        : message;

    AppNotificationMessenger.show(
      context,
      type: type,
      title: title,
      message: fullMessage,
      duration: duration,
    );

    onPrimaryPressed?.call();
  }
}
