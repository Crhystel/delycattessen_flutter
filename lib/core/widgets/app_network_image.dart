import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/app_image_cache_helper.dart';

/// Network photo that keeps its proportions.
///
/// It always uses [BoxFit.cover] by default and caps the decoded size using
/// ONE side only (the longest side of the box). Never fix `memCacheWidth` and
/// `memCacheHeight` together: the photo is decoded to those exact dimensions
/// ignoring its aspect ratio (like [BoxFit.fill]) and the picture looks
/// stretched, and a later `BoxFit.cover` cannot undo it.
///
/// [placeholder] shows while the photo loads. [error] shows when it fails and
/// also when [url] is null or empty.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.error,
  }) : _circular = false;

  /// Round photo of [size] x [size] (avatars). No fade, so [placeholder]
  /// (e.g. the initials) is replaced as soon as the photo is ready.
  const AppNetworkImage.circle({
    super.key,
    required this.url,
    required double size,
    this.placeholder,
    this.error,
  }) : width = size,
       height = size,
       fit = BoxFit.cover,
       _circular = true;

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? error;
  final bool _circular;

  // Same fades CachedNetworkImage uses by default.
  static const Duration _fadeIn = Duration(milliseconds: 500);
  static const Duration _fadeOut = Duration(milliseconds: 1000);

  bool get _hasUrl => url != null && url!.isNotEmpty;

  static bool _isFinite(double? value) =>
      value != null && value.isFinite && value > 0;

  @override
  Widget build(BuildContext context) {
    final fallback = error ?? const SizedBox.shrink();
    if (!_hasUrl) return _frame(fallback);

    // Fixed boxes need no LayoutBuilder (it does not support intrinsic sizes,
    // which matters inside IntrinsicHeight).
    if (_isFinite(width) && _isFinite(height)) {
      return _frame(_image(context, width!, height!, fallback));
    }
    return _frame(
      LayoutBuilder(
        builder: (context, constraints) {
          final w = _isFinite(width) ? width! : constraints.maxWidth;
          final h = _isFinite(height) ? height! : constraints.maxHeight;
          return _image(context, w, h, fallback);
        },
      ),
    );
  }

  Widget _image(
    BuildContext context,
    double logicalWidth,
    double logicalHeight,
    Widget fallback,
  ) {
    final useWidth =
        _isFinite(logicalWidth) &&
        (!_isFinite(logicalHeight) || logicalWidth >= logicalHeight);
    final side = useWidth ? logicalWidth : logicalHeight;
    final cache = AppImageCacheHelper.cacheSize(
      context,
      _isFinite(side) ? side : null,
    );
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      // Only ONE side: the photo keeps its aspect ratio.
      memCacheWidth: useWidth ? cache : null,
      memCacheHeight: useWidth ? null : cache,
      fadeInDuration: _circular ? Duration.zero : _fadeIn,
      fadeOutDuration: _circular ? Duration.zero : _fadeOut,
      placeholder: placeholder == null ? null : (_, _) => placeholder!,
      errorWidget: (_, _, _) => fallback,
    );
  }

  Widget _frame(Widget child) {
    var framed = child;
    if (width != null || height != null) {
      framed = SizedBox(width: width, height: height, child: framed);
    }
    return _circular ? ClipOval(child: framed) : framed;
  }
}
