import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_image_cache_helper.dart';
import '../../../core/utils/date_formatter.dart';

/// Common frame of an offer card (the combo): the image uploaded by
/// the admin as a slim strip (if any), a label, the title, the end date and
/// the [child] with the details. Everything flows with the available width and
/// text, so nothing has a fixed height.
class OfferCardFrame extends StatelessWidget {
  final String label;
  final String title;
  final DateTime endDate;
  final String? imageUrl;
  final Widget child;

  /// Opens the detail of the offer; shows an arrow next to the title.
  final VoidCallback? onTap;

  const OfferCardFrame({
    super.key,
    required this.label,
    required this.title,
    required this.endDate,
    required this.child,
    this.imageUrl,
    this.onTap,
  });

  static const double _imageAspectRatio = 16 / 6;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.brand500, width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: _buildContent(context, textTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUrl != null) _buildImage(context),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.brand500,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Text(
                      label,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Hasta el ${DateFormatter.formatShort(endDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.ink900.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.ink900.withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    return AspectRatio(
      aspectRatio: _imageAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) => CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          memCacheWidth: AppImageCacheHelper.cacheSize(
            context,
            constraints.maxWidth,
          ),
          placeholder: (_, _) => const ColoredBox(color: AppColors.ink50),
          errorWidget: (_, _, _) => const ColoredBox(color: AppColors.ink50),
        ),
      ),
    );
  }
}
