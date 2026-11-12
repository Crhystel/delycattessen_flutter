import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/base_scanner_screen.dart';

import '../services/pos_service.dart';
import '../../../core/utils/error_message.dart';

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

  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

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
      _availableCameras = cameras;
      // Default to back camera so cashier can point at student, or front if not available
      int initialIndex = cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      if (initialIndex == -1) initialIndex = 0;
      _selectedCameraIndex = initialIndex;

      await _startCameraController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al iniciar cámara: $e');
      }
    }
  }

  Future<void> _startCameraController(CameraDescription camera) async {
    final oldController = _cameraController;
    setState(() => _isCameraReady = false);
    await oldController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    if (!mounted) return;

    setState(() {
      _cameraController = controller;
      _isCameraReady = true;
    });
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isProcessing) return;
    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    await _startCameraController(_availableCameras[_selectedCameraIndex]);
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
        showErrorSnackBar(errorMessageOf(e), title: 'Identificación fallida');
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget? buildTopAction(BuildContext context) {
    if (_availableCameras.length < 2) return null;
    return ScannerRoundButton(
      icon: Icons.flip_camera_ios_rounded,
      tooltip: 'Cambiar cámara',
      onPressed: _isProcessing ? null : _switchCamera,
    );
  }

  /// Botón "Escanear rostro" (más pequeño en teléfono).
  @override
  Widget? buildPrimaryAction(BuildContext context) {
    final ready = _isCameraReady && !_isProcessing;
    final tablet = AppLayout.isTablet(context);
    final height = tablet ? 64.0 : 52.0;
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: ready ? _captureAndIdentify : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand500,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.brand500.withValues(alpha: 0.6),
          // El tema global estira los botones a todo el ancho; aquí no.
          minimumSize: Size(0, height),
          padding: EdgeInsets.symmetric(horizontal: tablet ? 36 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tablet ? 18 : 16),
          ),
        ),
        icon: _isProcessing
            ? SizedBox(
                width: tablet ? 26 : 20,
                height: tablet ? 26 : 20,
                child: const CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              )
            : Icon(Icons.camera_alt, size: tablet ? 30 : 22),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _isProcessing ? 'Identificando...' : 'Escanear rostro',
            style: TextStyle(
              fontSize: tablet ? 22 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
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
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand500),
      );
    }

    // previewSize viene en orientación del sensor (horizontal): en vertical
    // se intercambian ancho y alto; en horizontal se usan tal cual, si no la
    // imagen se deforma.
    final previewSize = _cameraController!.value.previewSize;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final cameraFeed = Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: (isPortrait ? previewSize?.height : previewSize?.width) ?? 1,
          height: (isPortrait ? previewSize?.width : previewSize?.height) ?? 1,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );

    // Solo la cámara y la guía; los botones los pone la plantilla base.
    final tablet = AppLayout.isTablet(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        cameraFeed,
        Icon(
          Icons.face_retouching_natural_rounded,
          color: AppColors.brand500.withValues(alpha: 0.45),
          size: tablet ? 180 : 120,
        ),
        if (_isProcessing)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.brand500),
            ),
          ),
      ],
    );
  }
}
