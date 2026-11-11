import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_network_image.dart';

/// Small rounded photo of a product inside an offer card; an icon when the
/// product has no photo or it is not in the catalog.
class OfferThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const OfferThumbnail({super.key, this.imageUrl, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: Container(
        width: size,
        height: size,
        color: AppColors.ink50,
        child: AppNetworkImage(
          url: imageUrl,
          width: size,
          height: size,
          error: const Icon(Icons.fastfood, color: AppColors.secondary500),
        ),
      ),
    );
  }
}
