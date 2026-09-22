import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Template Method Pattern: Defines the immutable standard scaffold and layout
/// for dark camera scanner screens (Figura 25 and Figura 26).
/// Subclasses only inject their specific camera/scanner viewfinder and text prompts.
abstract class BaseScannerScreen extends StatefulWidget {
  const BaseScannerScreen({super.key});

  @override
  State<BaseScannerScreen> createState();
}

abstract class BaseScannerScreenState<T extends BaseScannerScreen>
    extends State<T> with SingleTickerProviderStateMixin {
  late AnimationController animController;
  late Animation<double> scanAnimation;

  // Template methods to be implemented by child screens:
  String get screenTitle;
  String get instructionText;
  String get helpNoticeText;
  Widget buildScannerContent(BuildContext context);

  // Optional hooks:
  VoidCallback? get onCancelPressed => () => Navigator.of(context).pop();

  @override
  void initState() {
    super.initState();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    scanAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeInOut),
    );
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: onCancelPressed,
        ),
        title: Text(
          screenTitle,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Viewfinder Container with Orange/Golden Border
              Center(
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE5A93C), // Amber/Orange border
                      width: 3.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concrete Scanner content (Camera preview or scanner feed)
                      Positioned.fill(child: buildScannerContent(context)),

                      // Animated scanning line (cyan/electric blue)
                      AnimatedBuilder(
                        animation: scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: boxSize * scanAnimation.value,
                            left: 16,
                            right: 16,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4D8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00B4D8).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Instructional Text
              Text(
                instructionText,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // Information Notice Box (Dark deep navy with cyan accent bar - Figma)
              Center(
                child: Container(
                  width: (boxSize * 0.82).clamp(210.0, 250.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03192B), // Deep navy from Figma
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Cyan left accent bar
                        Container(
                          width: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0099FF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 12.0,
                            ),
                            child: Text(
                              helpNoticeText,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF0099FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // "Cancelar" Button (Black background with purple outline - Figma)
              Center(
                child: SizedBox(
                  width: (boxSize * 0.82).clamp(210.0, 250.0),
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onCancelPressed,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(
                        color: Color(0xFF5932EA), // Purple outline from Figma
                        width: 2.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF6F42C9),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
