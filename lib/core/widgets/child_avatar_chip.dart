import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Child avatar with a small purple ring (accent). Falls back to an icon.
class ChildAvatarChip extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ChildAvatarChip({super.key, this.imageUrl, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final size = (radius * 2 * MediaQuery.devicePixelRatioOf(context)).round();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.secondary500, width: 2),
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.secondary50,
        backgroundImage: hasImage
            ? ResizeImage(CachedNetworkImageProvider(imageUrl!), width: size)
            : null,
        child: hasImage
            ? null
            : const Icon(Icons.person, color: AppColors.secondary500),
      ),
    );
  }
}
