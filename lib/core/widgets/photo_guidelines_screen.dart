import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'face_capture_camera_screen.dart';
import 'floating_bubbles.dart';

class PhotoGuidelinesScreen extends StatelessWidget {
  final String title;

  const PhotoGuidelinesScreen({
    super.key,
    this.title = 'Foto de Perfil',
  });

  Future<void> _openCamera(BuildContext context) async {
    final photo = await Navigator.of(context).push<File?>(
      MaterialPageRoute(
        builder: (_) => FaceCaptureCameraScreen(title: title),
      ),
    );
    if (photo != null && context.mounted) {
      Navigator.of(context).pop(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Burbujas flotantes superiores e inferiores (estilo login)
          const FloatingBubbles(corner: BubbleCorner.topLeft),
          const FloatingBubbles(corner: BubbleCorner.bottomRight),

          // 2. Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Barra superior con botón volver
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.ink50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.ink900,
                            size: 22,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Centro con recomendaciones y botón de acción
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono de cabecera
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.teal50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.teal500,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Título principal
                          Text(
                            'Recomendaciones para la Foto',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Asegúrate de seguir estos puntos para que el reconocimiento facial sea rápido y preciso.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900.withValues(alpha: 0.65),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Contenedor destacado con los puntos de recomendación
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.lightbulb_rounded,
                                        color: Color(0xFF007ACC),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Puntos a tomar en cuenta:',
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _buildGuidelineItem(
                                  icon: Icons.wallpaper_rounded,
                                  title: 'Fondo blanco o neutro',
                                  description:
                                      'Utiliza una pared lisa, clara y sin sombras ni elementos distractores detrás.',
                                ),
                                _buildGuidelineItem(
                                  icon: Icons.wb_sunny_rounded,
                                  title: 'Buena iluminación frontal',
                                  description:
                                      'La luz debe iluminar el rostro directamente para evitar sombras pronunciadas.',
                                ),
                                _buildGuidelineItem(
                                  icon: Icons.face_rounded,
                                  title: 'Rostro centrado a la cámara',
                                  description:
                                      'Mira de frente con expresión natural, manteniendo la cámara a la altura de los ojos.',
                                ),
                                _buildGuidelineItem(
                                  icon: Icons.visibility_rounded,
                                  title: 'Sin accesorios invasivos',
                                  description:
                                      'Retira gorras, gafas oscuras, mascarillas o flequillos que cubran los ojos.',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Mensaje de UX para continuar
                          Text(
                            'Presiona el botón a continuación para abrir la cámara y capturar la fotografía.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Botón Entendido
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _openCamera(context),
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: Text(
                                'Entendido',
                                style: GoogleFonts.nunito(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary500,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.teal500, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
