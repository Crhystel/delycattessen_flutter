import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../auth/models/auth_models.dart';

/// Avatar del hijo: su foto o, si no tiene (o no carga), sus iniciales sobre un
/// color suave (azul, ámbar o morado según el hijo). [statusColor] pinta el
/// puntito de estado de la esquina (verde con saldo, rojo sin saldo).
///
/// Con [fixedTint] las iniciales van siempre en azul (`teal50`/`teal700`), como
/// en la ficha y en "Datos del hijo" del rediseño; sin él el color rota por hijo.
class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.child,
    this.radius = 24,
    this.statusColor,
    this.fixedTint = false,
  });

  final Child child;
  final double radius;
  final Color? statusColor;
  final bool fixedTint;

  static const (Color, Color) _fixedColors = (
    AppColors.teal50,
    AppColors.teal700,
  );

  static const List<(Color, Color)> _tints = [
    _fixedColors,
    (AppColors.brand50, AppColors.brand700),
    (AppColors.secondary50, AppColors.secondary700),
  ];

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = fixedTint
        ? _fixedColors
        : _tints[child.id % _tints.length];
    final url = child.profilePictureUrl;
    final hasImage = url != null && url.isNotEmpty;
    final size = AppImageCacheHelper.cacheSize(context, radius * 2);
    final dot = radius * 0.6;

    final initials = Text(
      child.initials,
      style: TextStyle(
        fontSize: radius * 0.66,
        fontWeight: fixedTint ? FontWeight.w800 : FontWeight.w700,
        color: foreground,
      ),
    );

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: background,
            // Initials show while the photo loads and when it fails.
            child: hasImage
                ? ClipOval(
                    child: Image(
                      image: ResizeImage(
                        CachedNetworkImageProvider(url),
                        width: size,
                        height: size,
                      ),
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      frameBuilder: (_, image, frame, wasSynchronouslyLoaded) =>
                          frame == null && !wasSynchronouslyLoaded
                          ? initials
                          : image,
                      errorBuilder: (_, _, _) => initials,
                    ),
                  )
                : initials,
          ),
          if (statusColor != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
