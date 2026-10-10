import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_notification_style.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'notification_header.dart';

export '../theme/app_notification_style.dart' show NotificationType;

/// Template Method: each subclass only declares its [type]; the look (header
/// colors and icon) comes from [AppNotificationStyle] and the structure
/// (header + title + message + optional X) is common to all.
abstract class NotificationSnackBarTemplate {
  final String message;
  final String? title;
  final Duration? duration;

  /// Cuando es true, desactiva el auto-dismiss por temporizador y el
  /// tap-anywhere-to-dismiss: solo se cierra con el botón X. Reservado para
  /// avisos que el usuario no debe poder descartar sin darse cuenta.
  final bool requireManualDismiss;

  /// Overrides opcionales de color para casos puntuales (p. ej. un aviso de
  /// advertencia que necesita verse más crítico) sin crear un tipo nuevo.
  final Color? headerBackgroundOverride;
  final Color? accentColorOverride;

  const NotificationSnackBarTemplate({
    required this.message,
    this.title,
    this.duration,
    this.requireManualDismiss = false,
    this.headerBackgroundOverride,
    this.accentColorOverride,
  });

  NotificationType get type;

  AppNotificationStyle get _style => AppNotificationStyle.of(type);

  Color get baseHeaderBackground => _style.background;
  Color get baseAccentColor => _style.accent;
  IconData get icon => _style.icon;

  Color get headerBackground =>
      headerBackgroundOverride ?? baseHeaderBackground;
  Color get accentColor => accentColorOverride ?? baseAccentColor;

  Widget buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.md),
      ),
      child: NotificationHeader(
        background: headerBackground,
        accent: accentColor,
        icon: icon,
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl - 4,
        AppSpacing.lg,
        AppSpacing.xl - 4,
        AppSpacing.xl - 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          if (title != null && title!.isNotEmpty)
            const SizedBox(height: AppSpacing.xs + 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink900.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCloseButton(VoidCallback onDismiss) {
    return Positioned(
      top: 8,
      right: 8,
      child: InkWell(
        onTap: onDismiss,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: AppColors.ink900,
          ),
        ),
      ),
    );
  }

  Widget buildContent(BuildContext context, {required VoidCallback onDismiss}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdAll,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [buildHeader(), buildBody(context)],
          ),
          if (requireManualDismiss) buildCloseButton(onDismiss),
        ],
      ),
    );
  }
}

class SuccessNotificationTemplate extends NotificationSnackBarTemplate {
  SuccessNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.requireManualDismiss,
    super.headerBackgroundOverride,
    super.accentColorOverride,
  });

  @override
  NotificationType get type => NotificationType.success;
}

class DangerNotificationTemplate extends NotificationSnackBarTemplate {
  DangerNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.requireManualDismiss,
    super.headerBackgroundOverride,
    super.accentColorOverride,
  });

  @override
  NotificationType get type => NotificationType.danger;
}

class WarningNotificationTemplate extends NotificationSnackBarTemplate {
  WarningNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.requireManualDismiss,
    super.headerBackgroundOverride,
    super.accentColorOverride,
  });

  @override
  NotificationType get type => NotificationType.warning;
}

class InfoNotificationTemplate extends NotificationSnackBarTemplate {
  InfoNotificationTemplate({
    required super.message,
    super.title,
    super.duration,
    super.requireManualDismiss,
    super.headerBackgroundOverride,
    super.accentColorOverride,
  });

  @override
  NotificationType get type => NotificationType.info;
}

/// Tarjeta flotante centrada, con animación simple de entrada/salida.
/// Se auto-cierra con temporizador y al tocar la pantalla, salvo que el
/// template exija cierre manual (solo entonces aparece el botón X).
class _FloatingNotificationCard extends StatefulWidget {
  final NotificationSnackBarTemplate template;
  final VoidCallback onDismiss;

  const _FloatingNotificationCard({
    required this.template,
    required this.onDismiss,
  });

  @override
  State<_FloatingNotificationCard> createState() =>
      _FloatingNotificationCardState();
}

class _FloatingNotificationCardState extends State<_FloatingNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    if (!widget.template.requireManualDismiss) {
      _autoDismissTimer = Timer(
        widget.template.duration ?? const Duration(seconds: 4),
        _dismiss,
      );
    }
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.template.requireManualDismiss ? null : _dismiss,
        child: Align(
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl + 4,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: widget.template.buildContent(
                    context,
                    onDismiss: _dismiss,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Punto único de entrada para mostrar notificaciones en toda la app.
class AppNotificationMessenger {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required NotificationType type,
    required String message,
    String? title,
    Duration? duration,
    bool requireManualDismiss = false,
    Color? headerBackgroundOverride,
    Color? accentColorOverride,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _currentEntry?.remove();
    _currentEntry = null;

    final template = _templateFor(
      type,
      message: message,
      title: title,
      duration: duration,
      requireManualDismiss: requireManualDismiss,
      headerBackgroundOverride: headerBackgroundOverride,
      accentColorOverride: accentColorOverride,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FloatingNotificationCard(
        template: template,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static NotificationSnackBarTemplate _templateFor(
    NotificationType type, {
    required String message,
    String? title,
    Duration? duration,
    bool requireManualDismiss = false,
    Color? headerBackgroundOverride,
    Color? accentColorOverride,
  }) {
    switch (type) {
      case NotificationType.success:
        return SuccessNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          requireManualDismiss: requireManualDismiss,
          headerBackgroundOverride: headerBackgroundOverride,
          accentColorOverride: accentColorOverride,
        );
      case NotificationType.danger:
        return DangerNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          requireManualDismiss: requireManualDismiss,
          headerBackgroundOverride: headerBackgroundOverride,
          accentColorOverride: accentColorOverride,
        );
      case NotificationType.warning:
        return WarningNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          requireManualDismiss: requireManualDismiss,
          headerBackgroundOverride: headerBackgroundOverride,
          accentColorOverride: accentColorOverride,
        );
      case NotificationType.info:
        return InfoNotificationTemplate(
          message: message,
          title: title,
          duration: duration,
          requireManualDismiss: requireManualDismiss,
          headerBackgroundOverride: headerBackgroundOverride,
          accentColorOverride: accentColorOverride,
        );
    }
  }
}

/// Mixin con atajos para usar en cualquier State sin repetir boilerplate.
mixin NotificationMixin<T extends StatefulWidget> on State<T> {
  void showNotificationSnackBar(
    NotificationType type,
    String message, {
    String? title,
    Duration? duration,
    bool requireManualDismiss = false,
    Color? headerBackgroundOverride,
    Color? accentColorOverride,
  }) {
    AppNotificationMessenger.show(
      context,
      type: type,
      message: message,
      title: title,
      duration: duration,
      requireManualDismiss: requireManualDismiss,
      headerBackgroundOverride: headerBackgroundOverride,
      accentColorOverride: accentColorOverride,
    );
  }

  void showSuccessSnackBar(
    String message, {
    String? title,
    Duration? duration,
  }) {
    showNotificationSnackBar(
      NotificationType.success,
      message,
      title: title,
      duration: duration,
    );
  }

  void showErrorSnackBar(String message, {String? title, Duration? duration}) {
    showNotificationSnackBar(
      NotificationType.danger,
      message,
      title: title,
      duration: duration,
    );
  }

  void showWarningSnackBar(
    String message, {
    String? title,
    Duration? duration,
  }) {
    showNotificationSnackBar(
      NotificationType.warning,
      message,
      title: title,
      duration: duration,
    );
  }

  /// Advertencia que el usuario debe cerrar a propósito con el botón X —
  /// sin auto-dismiss ni tap-anywhere — y con tonos rojizos para que
  /// destaque más que una advertencia normal. Pensada para casos puntuales
  /// (p. ej. alergias sin productos etiquetados) donde no queremos que se
  /// pierda por accidente.
  void showCriticalWarningSnackBar(String message, {String? title}) {
    showNotificationSnackBar(
      NotificationType.warning,
      message,
      title: title,
      requireManualDismiss: true,
      headerBackgroundOverride: AppColors.dangerBg,
      accentColorOverride: AppColors.danger500,
    );
  }

  void showInfoSnackBar(String message, {String? title, Duration? duration}) {
    showNotificationSnackBar(
      NotificationType.info,
      message,
      title: title,
      duration: duration,
    );
  }
}
