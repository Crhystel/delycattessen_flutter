import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_sheet.dart';
import 'app_notification_messenger.dart';
import 'photo_guidelines_screen.dart';

class PhotoSourceDialog {
  static Future<File?> show(
    BuildContext context, {
    String title = 'Foto de Perfil',
  }) async {
    final source = await AppBottomSheet.show<String>(
      context,
      title: title,
      subtitle: 'Selecciona de dónde deseas obtener la fotografía:',
      builder: (ctx) => Row(
        children: [
          Expanded(
            child: _SourceOption(
              icon: Icons.camera_alt_rounded,
              color: AppColors.teal500,
              label: 'Tomar foto',
              caption: 'Cámara en vivo',
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _SourceOption(
              icon: Icons.photo_library_rounded,
              color: AppColors.brand500,
              label: 'Galería',
              caption: 'Elegir archivo',
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
          ),
        ],
      ),
    );

    if (source == 'camera' && context.mounted) {
      return Navigator.of(context).push<File?>(
        MaterialPageRoute(builder: (_) => PhotoGuidelinesScreen(title: title)),
      );
    } else if (source == 'gallery') {
      try {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (picked != null) return File(picked.path);
      } catch (e) {
        if (context.mounted) {
          AppNotificationMessenger.show(
            context,
            type: NotificationType.danger,
            title: 'No se pudo abrir la galería',
            message: e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
    return null;
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String caption;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl - 4),
        decoration: BoxDecoration(
          color: AppColors.ink50,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.teal50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                icon,
                // Dark icon on the yellow circle, white on the blue one.
                color: color == AppColors.brand500
                    ? AppColors.ink900
                    : Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              caption,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.ink900.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
