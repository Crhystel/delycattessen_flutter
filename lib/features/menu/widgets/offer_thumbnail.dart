import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/app_image_cache_helper.dart';

/// Small rounded photo of a product inside an offer card; an icon when the
/// product has no photo or it is not in the catalog.
class OfferThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const OfferThumbnail({super.key, this.imageUrl, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: Container(
        width: size,
        height: size,
        color: AppColors.ink50,
        child: url == null || url.isEmpty
            ? const Icon(Icons.fastfood, color: AppColors.secondary500)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: AppImageCacheHelper.cacheSize(context, size),
                memCacheHeight: AppImageCacheHelper.cacheSize(context, size),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.fastfood, color: AppColors.secondary500),
              ),
      ),
    );
  }
}
