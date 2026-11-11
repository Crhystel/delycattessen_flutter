import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_network_image.dart';

/// Big photo at the top of a detail screen (product, combo) with the back
/// arrow over it. Falls back to an icon when there is no photo.
class DetailHeroImage extends StatelessWidget {
  final String? imageUrl;

  const DetailHeroImage({super.key, this.imageUrl});

  static const double _maxHeight = 280;
  static const double _minHeight = 120;

  /// Share of the screen height the photo may take, so the details and the
  /// add bar always have room (landscape phones are only ~360 dp tall).
  static const double _screenShare = 0.4;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * _screenShare).clamp(
      _minHeight,
      _maxHeight,
    );
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: height,
          color: AppColors.ink50,
          child: AppNetworkImage(
            url: imageUrl,
            width: double.infinity,
            height: height,
            placeholder: const Center(
              child: CircularProgressIndicator(color: AppColors.secondary500),
            ),
            error: const _FallbackIcon(),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.ink900,
                ),
                tooltip: 'Volver',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.fastfood, size: 100, color: AppColors.secondary500);
  }
}
