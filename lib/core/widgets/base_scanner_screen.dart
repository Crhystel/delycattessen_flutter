import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_notification_messenger.dart';
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
}
