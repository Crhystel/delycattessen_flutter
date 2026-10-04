import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum NotificationType { success, danger, warning, info }

/// Template Method: cada tipo define su color de header, ícono y acento.
/// La estructura (header con círculos + ícono + título + mensaje + X) es
/// común a todas.
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

  Color get baseHeaderBackground;
  Color get baseAccentColor;
  IconData get icon;

  Color get headerBackground =>
      headerBackgroundOverride ?? baseHeaderBackground;
  Color get accentColor => accentColorOverride ?? baseAccentColor;

  /// Header decorativo: fondo suave del tipo + círculos flotantes en los
  /// tres colores de marca, con el ícono de estado centrado como badge.
  Widget buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: 96,
        width: double.infinity,
        color: headerBackground,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -26,
              top: -26,
              child: _floatingCircle(76, AppColors.brand500, 0.55),
            ),
            Positioned(
              right: -16,
              top: -6,
              child: _floatingCircle(50, AppColors.teal500, 0.55),
            ),
            Positioned(
              right: 16,
              bottom: -26,
              child: _floatingCircle(60, AppColors.secondary500, 0.5),
            ),
            Positioned(
              left: 36,
              bottom: -18,
              child: _floatingCircle(32, AppColors.teal500, 0.4),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }

  Widget buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
          if (title != null && title!.isNotEmpty) const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
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
        borderRadius: BorderRadius.circular(20),
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
            children: [buildHeader(), buildBody()],
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
  Color get baseHeaderBackground => AppColors.successBg;

  @override
  Color get baseAccentColor => AppColors.success500;

  @override
  IconData get icon => Icons.check_rounded;
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
  Color get baseHeaderBackground => AppColors.dangerBg;

  @override
  Color get baseAccentColor => AppColors.danger500;

  @override
  IconData get icon => Icons.close_rounded;
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
  Color get baseHeaderBackground => AppColors.warningBg;

  @override
  Color get baseAccentColor => AppColors.warning500;

  @override
  IconData get icon => Icons.priority_high_rounded;
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
  Color get baseHeaderBackground => AppColors.teal50;

  @override
  Color get baseAccentColor => AppColors.teal500;

  @override
  IconData get icon => Icons.info_rounded;
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
                padding: const EdgeInsets.symmetric(horizontal: 36),
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
