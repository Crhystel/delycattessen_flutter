import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Tipos de notificación disponibles en el sistema Delycattessen.
enum NotificationType { success, danger, warning, info }

/// ============================================================================
/// PATRÓN TEMPLATE METHOD:
/// Define el esqueleto del algoritmo de construcción del SnackBar para
/// ScaffoldMessenger. Las subclases concretas definen los colores, iconos
/// e indicadores visuales específicos según el tipo de notificación.
/// ============================================================================
abstract class NotificationSnackBarTemplate {
  final String message;
  final String? title;
  final Duration? duration;
  final IconData? customIcon;
  final SnackBarAction? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NotificationSnackBarTemplate({
    required this.message,
    this.title,
    this.duration,
    this.customIcon,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  /// Métodos abstractos/primitivos que cada subclase concreta debe implementar:
  Color get accentColor;
  Color get iconBackgroundColor;
  Color get iconColor;
  IconData get defaultIcon;

  /// Hook para el contenedor o borde (por defecto blanco con sombra suave y borde temático)
  Color get cardBackgroundColor => Colors.white;

  /// Icono final a mostrar
  IconData get resolvedIcon => customIcon ?? defaultIcon;

  /// Template Method: Orquesta y construye el SnackBar inmutable para ScaffoldMessenger
  SnackBar buildSnackBar(BuildContext context) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.zero,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
      content: buildContent(context),
    );
  }

  /// Construye el contenido visual tipo tarjeta flotante
  Widget buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildLeadingIcon(),
          const SizedBox(width: 12),
          Expanded(child: buildBody()),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            buildAction(context),
          ],
        ],
      ),
    );
  }

  /// Paso del template: Construcción del icono circular con badge de color
  Widget buildLeadingIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        resolvedIcon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  /// Paso del template: Construcción de textos (título opcional + mensaje)
  Widget buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Text(
            title!,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          message,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink900.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  /// Paso del template: Construcción del botón de acción lateral
  Widget buildAction(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        onAction?.call();
      },
      child: Text(
        actionLabel!,
        style: GoogleFonts.nunito(
          color: accentColor,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Factoría para instanciar la plantilla correcta según [NotificationType]
  static NotificationSnackBarTemplate of({
    required NotificationType type,
    required String message,
    String? title,
    Duration? duration,
    IconData? customIcon,
    SnackBarAction? action,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    switch (type) {
      case NotificationType.success:
        return SuccessNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          customIcon: customIcon,
          action: action,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      case NotificationType.danger:
        return DangerNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          customIcon: customIcon,
          action: action,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      case NotificationType.warning:
        return WarningNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          customIcon: customIcon,
          action: action,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      case NotificationType.info:
        return InfoNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          customIcon: customIcon,
          action: action,
          actionLabel: actionLabel,
          onAction: onAction,
        );
    }
  }
}

/// Template concreto para notificaciones de ÉXITO
class SuccessNotificationTemplate extends NotificationSnackBarTemplate {
  const SuccessNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.customIcon,
    super.action,
    super.actionLabel,
    super.onAction,
  });

  @override
  Color get accentColor => AppColors.success500;

  @override
  Color get iconBackgroundColor => AppColors.successBg;

  @override
  Color get iconColor => AppColors.success700;

  @override
  IconData get defaultIcon => Icons.check_circle_rounded;
}

/// Template concreto para notificaciones de ERROR / PELIGRO
class DangerNotificationTemplate extends NotificationSnackBarTemplate {
  const DangerNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.customIcon,
    super.action,
    super.actionLabel,
    super.onAction,
  });

  @override
  Color get accentColor => AppColors.danger500;

  @override
  Color get iconBackgroundColor => AppColors.dangerBg;

  @override
  Color get iconColor => AppColors.danger700;

  @override
  IconData get defaultIcon => Icons.error_rounded;
}

/// Template concreto para notificaciones de ADVERTENCIA
class WarningNotificationTemplate extends NotificationSnackBarTemplate {
  const WarningNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.customIcon,
    super.action,
    super.actionLabel,
    super.onAction,
  });

  @override
  Color get accentColor => AppColors.warning500;

  @override
  Color get iconBackgroundColor => AppColors.warningBg;

  @override
  Color get iconColor => AppColors.warning700;

  @override
  IconData get defaultIcon => Icons.warning_amber_rounded;
}

/// Template concreto para notificaciones INFORMATIVAS
class InfoNotificationTemplate extends NotificationSnackBarTemplate {
  const InfoNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.customIcon,
    super.action,
    super.actionLabel,
    super.onAction,
  });

  @override
  Color get accentColor => AppColors.teal500;

  @override
  Color get iconBackgroundColor => AppColors.teal50;

  @override
  Color get iconColor => AppColors.teal700;

  @override
  IconData get defaultIcon => Icons.info_rounded;
}

/// ============================================================================
/// FACHADA / HELPER: AppNotificationMessenger
/// Permite mostrar notificaciones mediante ScaffoldMessenger de forma estática
/// y limpia en cualquier lugar donde se tenga acceso a un BuildContext.
/// ============================================================================
class AppNotificationMessenger {
  AppNotificationMessenger._();

  /// Muestra una notificación con ScaffoldMessenger usando la plantilla correspondiente
  static void show(
    BuildContext context, {
    required NotificationType type,
    required String message,
    String? title,
    Duration? duration,
    IconData? icon,
    SnackBarAction? action,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final template = NotificationSnackBarTemplate.of(
      type: type,
      message: message,
      title: title,
      duration: duration,
      customIcon: icon,
      action: action,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(template.buildSnackBar(context));
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: NotificationType.success,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: NotificationType.danger,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: NotificationType.warning,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: NotificationType.info,
      message: message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }
}

/// ============================================================================
/// PATRÓN MIXIN: NotificationMixin
/// Permite que cualquier `State<T>` de un StatefulWidget consuma el sistema
/// de notificaciones ScaffoldMessenger de forma directa y limpia sin
/// boilerplate.
/// ============================================================================
mixin NotificationMixin<T extends StatefulWidget> on State<T> {
  void showSuccessSnackBar(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    AppNotificationMessenger.showSuccess(
      context,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showErrorSnackBar(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    AppNotificationMessenger.showError(
      context,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showWarningSnackBar(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    AppNotificationMessenger.showWarning(
      context,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showInfoSnackBar(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    AppNotificationMessenger.showInfo(
      context,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showNotificationSnackBar({
    required NotificationType type,
    required String message,
    String? title,
    Duration? duration,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    AppNotificationMessenger.show(
      context,
      type: type,
      message: message,
      title: title,
      duration: duration,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
