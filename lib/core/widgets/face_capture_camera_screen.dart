import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

class FaceCaptureCameraScreen extends StatefulWidget {
  final String title;

  const FaceCaptureCameraScreen({
    super.key,
    this.title = 'Foto de Perfil',
  });

  @override
  State<FaceCaptureCameraScreen> createState() => _FaceCaptureCameraScreenState();
}

class _FaceCaptureCameraScreenState extends State<FaceCaptureCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  String? _errorMessage;
  File? _capturedFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No se encontró ninguna cámara disponible.');
        return;
      }
      _availableCameras = cameras;

      // Prefer back camera for parent taking photo of student, or front if back unavailable
      int initialIndex = cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      if (initialIndex == -1) initialIndex = 0;
      _selectedCameraIndex = initialIndex;

      await _startCameraController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al acceder a la cámara: $e');
      }
    }
  }

  Future<void> _startCameraController(CameraDescription camera) async {
    final oldController = _cameraController;
    setState(() => _isCameraReady = false);
    await oldController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al inicializar cámara: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isCapturing) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _startCameraController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() => _isCapturing = true);
      final XFile photo = await _cameraController!.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedFile = File(photo.path);
        _isCapturing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar la foto: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _capturedFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _retake() {
    setState(() => _capturedFile = null);
  }

  void _confirmAndReturn() {
    if (_capturedFile != null) {
      Navigator.of(context).pop(_capturedFile);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Camera Preview or Captured Image Preview
          if (_capturedFile != null)
            Image.file(
              _capturedFile!,
              fit: BoxFit.cover,
            )
          else if (_isCameraReady && _cameraController != null)
            _buildFullscreenCameraPreview()
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 2. Oval Guide Silhouette (only when taking live photo)
          if (_capturedFile == null && _isCameraReady)
            Center(
              child: Container(
                width: 250,
                height: 330,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(125, 165)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 2.5,
                  ),
                ),
              ),
            ),

          // 3. Top Bar (Close button & Title)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      widget.title,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          const Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance close button
                  ],
                ),
              ),
            ),
          ),


          // 5. Bottom Controls Bar
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _capturedFile == null
                    ? _buildCaptureControls()
                    : _buildReviewControls(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenCameraPreview() {
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(_cameraController!),
      ),
    );
  }


  Widget _buildCaptureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Gallery Button
        IconButton(
          tooltip: 'Elegir de galería',
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 26),
          ),
          onPressed: _pickFromGallery,
        ),

        // Shutter Button
        GestureDetector(
          onTap: _takePhoto,
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: _isCapturing
                  ? const CircularProgressIndicator(color: AppColors.teal500)
                  : null,
            ),
          ),
        ),

        // Switch Camera Button
        IconButton(
          tooltip: 'Cambiar cámara',
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 26),
          ),
          onPressed: _switchCamera,
        ),
      ],
    );
  }

  Widget _buildReviewControls() {
    return Row(
      children: [
        // Retake Button
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.white, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _retake,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text(
              'Repetir',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Use Photo Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5932EA),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: _confirmAndReturn,
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: Text(
              'Usar foto',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
