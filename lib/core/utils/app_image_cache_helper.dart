import 'package:flutter/widgets.dart';

/// Helper utility to calculate optimal in-memory cache dimensions for decoded images
/// based on display size in logical pixels and device pixel ratio.
class AppImageCacheHelper {
  AppImageCacheHelper._();

  /// Calculates cache dimension in physical pixels given logical [size] and [context].
  static int? cacheSize(BuildContext context, double? size) {
    if (size == null || size <= 0) return null;
    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    return (size * pixelRatio).round();
  }

  /// Calculates cache dimension in physical pixels given logical [size] and explicit [pixelRatio].
  static int? cacheSizeWithRatio(double? size, double pixelRatio) {
    if (size == null || size <= 0) return null;
    return (size * pixelRatio).round();
  }
}
