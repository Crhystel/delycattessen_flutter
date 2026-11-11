import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_network_image.dart';

/// Child avatar with a small purple ring (accent). Falls back to an icon.
class ChildAvatarChip extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ChildAvatarChip({super.key, this.imageUrl, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.person, color: AppColors.secondary500);
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
        child: AppNetworkImage.circle(
          url: imageUrl,
          size: radius * 2,
          placeholder: const Center(child: icon),
          error: const Center(child: icon),
        ),
      ),
    );
  }
}
