import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
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

  /// En tablet la cámara ocupa toda la pantalla; en teléfono se usa el
  /// recuadro del Figma (Figura 25 y 26).
  bool get isFullScreen => AppLayout.isTablet(context);

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

  @override
  Widget build(BuildContext context) {
    if (isFullScreen) return _buildFullScreen(context);
    final screenSize = MediaQuery.of(context).size;
    final boxSize = (screenSize.width * 0.72).clamp(240.0, 300.0);
    final noticeWidth = (boxSize * 0.82).clamp(210.0, 250.0);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: onCancelPressed,
        ),
        title: Text(screenTitle),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Center(
                child: ScannerFrame(
                  size: boxSize,
                  scanAnimation: scanAnimation,
                  child: buildScannerContent(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl - 4),
              Text(
                instructionText,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: ScannerNotice(text: helpNoticeText, width: noticeWidth),
              ),
              const Spacer(flex: 2),
              Center(
                child: SizedBox(
                  width: noticeWidth,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onCancelPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary500,
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(
                        color: Color(0xFF5932EA),
                        width: 2.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl - 4),
            ],
          ),
        ),
      ),
    );
  }

  /// Vista de tablet: la cámara llena la pantalla y los controles, grandes,
  /// van arriba y abajo sobre degradados oscuros. El recuadro guía se dibuja
  /// solo en el espacio libre entre ambos, para que nada lo tape.
  Widget _buildFullScreen(BuildContext context) {
    final primary = buildPrimaryAction(context);
    final topAction = buildTopAction(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: buildScannerContent(context)),
          Column(
            children: [
              _buildTopBar(topAction),
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
              _buildBottomPanel(primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Widget? topAction) {
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
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  screenTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
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

  Widget _buildBottomPanel(Widget? primary) {
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                instructionText.replaceAll('\n', ' '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ScannerNotice(
                text: helpNoticeText.replaceAll('\n', ' '),
                width: 560,
                fontSize: 18,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.md,
                children: [
                  ?primary,
                  SizedBox(
                    width: 240,
                    height: 64,
                    child: OutlinedButton(
                      onPressed: onCancelPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 64),
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón circular grande y semitransparente para la vista de cámara en tablet.
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
      ),
    );
  }
}
