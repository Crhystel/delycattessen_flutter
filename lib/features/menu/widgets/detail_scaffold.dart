import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_network_image.dart';
import 'detail_tag.dart';

/// Page of the detail redesign (dish, product, combo): the photo with the back
/// button and [tag] over it, and a rounded sheet that rises over the photo
/// holding [children], spaced evenly. Everything scrolls except [bottomBar].
class DetailScaffold extends StatelessWidget {
  final DetailTag tag;
  final String? imageUrl;
  final List<Widget> children;

  /// Fixed at the bottom (quantity bar or blocked bar); null = none.
  final Widget? bottomBar;

  const DetailScaffold({
    super.key,
    required this.tag,
    required this.children,
    this.imageUrl,
    this.bottomBar,
  });

  static const double _maxPhotoHeight = 280;
  static const double _minPhotoHeight = 120;

  /// Share of the screen height the photo may take, so the details and the
  /// bar always have room (landscape phones are only ~360 dp tall).
  static const double _screenShare = 0.4;

  static const double _backButtonSize = 44;

  @override
  Widget build(BuildContext context) {
    final photoHeight = (MediaQuery.sizeOf(context).height * _screenShare)
        .clamp(_minPhotoHeight, _maxPhotoHeight);
    return Scaffold(
      backgroundColor: AppColors.ink50,
      body: ResponsiveCenter(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    _Photo(url: imageUrl, height: photoHeight),
                    Padding(
                      padding: EdgeInsets.only(top: photoHeight - AppRadius.lg),
                      child: _Sheet(children: children),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Row(
                            children: [
                              const _BackButton(),
                              const Spacer(),
                              Flexible(child: tag),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ?bottomBar,
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String? url;
  final double height;

  const _Photo({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.brand50,
      child: AppNetworkImage(
        url: url,
        width: double.infinity,
        height: height,
        placeholder: const Center(
          child: CircularProgressIndicator(color: AppColors.secondary500),
        ),
        error: const Icon(
          Icons.fastfood,
          size: 100,
          color: AppColors.secondary500,
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final List<Widget> children;

  const _Sheet({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        22,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.ink50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.block),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DetailScaffold._backButtonSize,
      height: DetailScaffold._backButtonSize,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
        tooltip: 'Volver',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
