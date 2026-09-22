import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/base_scanner_screen.dart';

import '../services/pos_service.dart';


class FaceRecognitionScanScreen extends BaseScannerScreen {
  const FaceRecognitionScanScreen({super.key});

  @override
  State<FaceRecognitionScanScreen> createState() =>
      _FaceRecognitionScanScreenState();
}

class _FaceRecognitionScanScreenState
    extends BaseScannerScreenState<FaceRecognitionScanScreen> {
  final PosService _posService = PosService();
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  String get screenTitle => 'Reconocimiento Facial';

  @override
  String get instructionText =>
      'Coloca el rostro del usuario\ndentro del encuadre';

  @override
  String get helpNoticeText =>
      'Asegúrate de tener\nbuena iluminación y\nque el rostro esté\ncentrado.';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No se detectó cámara disponible.');
        return;
      }
      // Prefer front camera for portrait face capture, or back camera if not available
      final selectedCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al iniciar cámara: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndIdentify() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final xFile = await _cameraController!.takePicture();
      final user = await _posService.identifyByFace(xFile.path);

      if (mounted) {
        Navigator.of(context).pop(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE0473E),
            content: Text(
              'Identificación fallida: ${e.toString().replaceAll("Exception: ", "")}',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget buildScannerContent(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(color: Colors.white70, fontSize: 13),
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5A93C)),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera Viewfinder Feed
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),

        // Stylized Orange Face Outline (Figura 25)
        Icon(
          Icons.face_retouching_natural_rounded,
          color: const Color(0xFFE5A93C).withValues(alpha: 0.7),
          size: 110,
        ),

        // Shutter / Capture Trigger Overlay Button
        Positioned(
          bottom: 12,
          child: GestureDetector(
            onTap: _isProcessing ? null : _captureAndIdentify,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A93C),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _isProcessing ? 'Identificando...' : 'Escanear Rostro',
                    style: GoogleFonts.nunito(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
