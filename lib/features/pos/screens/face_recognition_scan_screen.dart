import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/theme/app_colors.dart';
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
        showErrorSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          title: 'Identificación fallida',
        );
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

  /// Botón grande "Escanear rostro" de la vista de tablet.
  @override
  Widget? buildPrimaryAction(BuildContext context) {
    final ready = _isCameraReady && !_isProcessing;
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        onPressed: ready ? _captureAndIdentify : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand500,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.brand500.withValues(alpha: 0.6),
          // El tema global estira los botones a todo el ancho; aquí no.
          minimumSize: const Size(0, 64),
          padding: const EdgeInsets.symmetric(horizontal: 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _isProcessing
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.camera_alt, size: 30),
        label: Text(
          _isProcessing ? 'Identificando...' : 'Escanear rostro',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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

    // Tablet: solo la cámara; los botones grandes los pone la plantilla base.
    if (isFullScreen) {
      return Stack(
        alignment: Alignment.center,
        children: [
          cameraFeed,
          Icon(
            Icons.face_retouching_natural_rounded,
            color: AppColors.brand500.withValues(alpha: 0.45),
            size: 180,
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

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera Viewfinder Feed
        cameraFeed,

        // Stylized Orange Face Outline (Figura 25)
        Icon(
          Icons.face_retouching_natural_rounded,
          color: AppColors.brand500.withValues(alpha: 0.7),
          size: 110,
        ),

        // Camera Switch Button (Top-Right)
        if (_availableCameras.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _isProcessing ? null : _switchCamera,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flip_camera_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

        // Shutter / Capture Trigger Overlay Button
        Positioned(
          bottom: 12,
          child: GestureDetector(
            onTap: _isProcessing ? null : _captureAndIdentify,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand500,
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
                    style: const TextStyle(
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
