import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/base_scanner_screen.dart';

import '../services/pos_service.dart';


class QrScanScreen extends BaseScannerScreen {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends BaseScannerScreenState<QrScanScreen> {
  final PosService _posService = PosService();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  String get screenTitle => 'Código QR';

  @override
  String get instructionText =>
      'Apunta la cámara al código QR\ndel usuario para escanearlo';

  @override
  String get helpNoticeText =>
      'Mantén el QR\nestable y a una\ndistancia correcta';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawCode = barcodes.first.rawValue;
    if (rawCode == null || rawCode.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final user = await _posService.identifyByQr(rawCode.trim());
      if (mounted) {
        Navigator.of(context).pop(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE0473E),
            content: Text(
              'Error al validar QR: ${e.toString().replaceAll("Exception: ", "")}',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        // Cooldown before scanning again
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget buildScannerContent(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Live Mobile QR Scanner Viewfinder
        Positioned.fill(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
        ),

        // Stylized Amber QR Icon Overlay (Figura 26)
        Icon(
          Icons.qr_code_2_rounded,
          color: const Color(0xFFE5A93C).withValues(alpha: 0.35),
          size: 130,
        ),

        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A93C)),
            ),
          ),
      ],
    );
  }
}
