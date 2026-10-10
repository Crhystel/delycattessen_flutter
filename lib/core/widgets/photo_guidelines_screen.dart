import 'dart:io';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'face_capture_camera_screen.dart';
import 'primary_button.dart';

class PhotoGuidelinesScreen extends StatelessWidget {
  final String title;

  const PhotoGuidelinesScreen({super.key, this.title = 'Foto de Perfil'});

  Future<void> _openCamera(BuildContext context) async {
    final photo = await Navigator.of(context).push<File?>(
      MaterialPageRoute(builder: (_) => FaceCaptureCameraScreen(title: title)),
    );
    if (photo != null && context.mounted) {
      Navigator.of(context).pop(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: AppColors.teal50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.teal500,
                    size: 34,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Recomendaciones para la foto',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Asegúrate de seguir estos puntos para que el reconocimiento facial sea rápido y preciso.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl - 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: AppColors.brand50,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              color: AppColors.brand700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Puntos a tomar en cuenta',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _GuidelineItem(
                        icon: Icons.wallpaper_rounded,
                        title: 'Fondo blanco o neutro',
                        description:
                            'Utiliza una pared lisa, clara y sin sombras ni elementos distractores detrás.',
                      ),
                      const _GuidelineItem(
                        icon: Icons.wb_sunny_rounded,
                        title: 'Buena iluminación frontal',
                        description:
                            'La luz debe iluminar el rostro directamente para evitar sombras pronunciadas.',
                      ),
                      const _GuidelineItem(
                        icon: Icons.face_rounded,
                        title: 'Rostro centrado a la cámara',
                        description:
                            'Mira de frente con expresión natural, manteniendo la cámara a la altura de los ojos.',
                      ),
                      const _GuidelineItem(
                        icon: Icons.visibility_rounded,
                        title: 'Sin accesorios invasivos',
                        description:
                            'Retira gorras, gafas oscuras, mascarillas o flequillos que cubran los ojos.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Presiona el botón a continuación para abrir la cámara y capturar la fotografía.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Entendido',
                  icon: Icons.camera_alt_rounded,
                  onPressed: () => _openCamera(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _GuidelineItem({
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.teal50,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: AppColors.teal500, size: 20),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.ink900.withValues(alpha: 0.7),
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
