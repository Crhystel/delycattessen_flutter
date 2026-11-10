import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../storage/token_storage.dart';
import '../widgets/app_notification_messenger.dart';

/// Único dueño del cierre forzado de sesión (cuenta desactivada o sesión
/// vencida): borra los tokens, lleva al login y avisa al usuario.
class SessionManager {
  SessionManager._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static bool _expiring = false;

  static Future<void> expire(
    String message, {
    String title = 'Sesión finalizada',
  }) async {
    if (_expiring) return;
    _expiring = true;
    try {
      await TokenStorage.clear();

      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      // Después del frame para que reemplace cualquier error que la pantalla
      // anterior alcance a mostrar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context == null) return;
        AppNotificationMessenger.show(
          context,
          type: NotificationType.danger,
          title: title,
          message: message,
          duration: const Duration(seconds: 6),
        );
      });
    } finally {
      // Permite un nuevo cierre forzado tras un login posterior.
      Future<void>.delayed(const Duration(seconds: 2), () => _expiring = false);
    }
  }
}
