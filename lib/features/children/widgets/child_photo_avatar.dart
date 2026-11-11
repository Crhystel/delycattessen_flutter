import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/auth_models.dart';
import 'child_avatar.dart';

/// Avatar de 64 del hijo con la insignia de cámara (30, amarilla, borde
/// blanco) en la esquina: al tocarla se cambia la foto. Mientras se sube la
/// foto nueva ([isUpdating]) muestra un indicador de carga.
class ChildPhotoAvatar extends StatelessWidget {
  const ChildPhotoAvatar({
    super.key,
    required this.child,
    required this.isUpdating,
    required this.onChangePhoto,
  });

  final Child child;
  final bool isUpdating;
  final VoidCallback onChangePhoto;

  static const double _radius = 32;
  static const double _badgeSize = 30;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _radius * 2,
      height: _radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isUpdating)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.secondary500,
                ),
              ),
            )
          else
            ChildAvatar(child: child, radius: _radius, fixedTint: true),
          Positioned(
            right: -6,
            bottom: -6,
            child: Semantics(
              button: true,
              enabled: !isUpdating,
              label: 'Cambiar foto',
              child: GestureDetector(
                onTap: isUpdating ? null : onChangePhoto,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand500,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    size: 14,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
