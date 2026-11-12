import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_notification_messenger.dart';
import 'scanner_overlay.dart';

/// Template Method Pattern: Defines the immutable standard scaffold and layout
/// for dark camera scanner screens (Figura 25 and Figura 26).
/// Subclasses only inject their specific camera/scanner viewfinder and text prompts.
abstract class BaseScannerScreen extends StatefulWidget {
  const BaseScannerScreen({super.key});

  @override
  State<BaseScannerScreen> createState();
}

abstract class BaseScannerScreenState<T extends BaseScannerScreen>
    extends State<T>
    with SingleTickerProviderStateMixin, NotificationMixin<T> {
  late AnimationController animController;
  late Animation<double> scanAnimation;

  // Template methods to be implemented by child screens:
  String get screenTitle;
  String get instructionText;
  String get helpNoticeText;
  Widget buildScannerContent(BuildContext context);

  // Optional hooks:
  VoidCallback? get onCancelPressed =>
      () => Navigator.of(context).pop();

  /// Botón principal bajo la instrucción en la vista de tablet (p. ej.
  /// "Escanear rostro"). Null = sin botón (el QR se detecta solo).
  Widget? buildPrimaryAction(BuildContext context) => null;

  /// Acción en la barra superior de la vista de tablet (p. ej. cambiar cámara).
  Widget? buildTopAction(BuildContext context) => null;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    scanAnimation = Tween<double>(
      begin: 0.15,
      end: 0.85,
    ).animate(CurvedAnimation(parent: animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  /// En tablet y en teléfono la cámara llena la pantalla y los controles van
  /// arriba y abajo sobre degradados oscuros (más compactos en teléfono). El
  /// recuadro guía se dibuja solo en el espacio libre entre ambos, para que
  /// nada lo tape.
  @override
  Widget build(BuildContext context) {
    final primary = buildPrimaryAction(context);
    final topAction = buildTopAction(context);
    final tablet = AppLayout.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: buildScannerContent(context)),
          Column(
            children: [
              _buildTopBar(topAction, tablet),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final frameSize =
                        constraints.biggest.shortestSide.clamp(0.0, 520.0) *
                        0.85;
                    return Center(
                      child: IgnorePointer(
                        child: ScannerFrame(
                          size: frameSize,
                          scanAnimation: scanAnimation,
                          filled: false,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildBottomPanel(primary, tablet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Widget? topAction, bool tablet) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              ScannerRoundButton(
                icon: Icons.arrow_back,
                tooltip: 'Volver',
                onPressed: onCancelPressed,
              ),
              SizedBox(width: tablet ? AppSpacing.lg : AppSpacing.md),
              Expanded(
                child: Text(
                  screenTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tablet ? 30 : 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?topAction,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(Widget? primary, bool tablet) {
    final cancel = SizedBox(
      width: tablet ? 240 : null,
      height: tablet ? 64 : 52,
      child: OutlinedButton(
        onPressed: onCancelPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: Size(0, tablet ? 64 : 52),
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tablet ? 18 : 16),
          ),
        ),
        child: Text(
          'Cancelar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: tablet ? 22 : 17,
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.black87, Colors.transparent],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tablet ? AppSpacing.xl : AppSpacing.page,
            AppSpacing.xl,
            tablet ? AppSpacing.xl : AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                instructionText.replaceAll('\n', ' '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: tablet ? 26 : 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ScannerNotice(
                text: helpNoticeText.replaceAll('\n', ' '),
                width: tablet ? 560 : double.infinity,
                fontSize: tablet ? 18 : 13,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (tablet)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.md,
                  children: [?primary, cancel],
                )
              else
                // Phone: both actions share the row, or Cancel takes it all.
                Row(
                  children: [
                    if (primary != null) ...[
                      Expanded(flex: 3, child: primary),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(flex: 2, child: cancel),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón circular semitransparente para la vista de cámara (más pequeño en
/// teléfono).
class ScannerRoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const ScannerRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tablet = AppLayout.isTablet(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(tablet ? 14 : 10),
            child: Icon(icon, color: Colors.white, size: tablet ? 34 : 26),
          ),
        ),
      ),
    );
  }
}
