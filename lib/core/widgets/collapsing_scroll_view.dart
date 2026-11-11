import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'collapsing_fold_scope.dart';

/// Vertical scroll view whose `CollapsingHeader` always folds completely when
/// the user scrolls, however few items the list has.
///
/// On its own the header folds 1 to 1 with the scroll, so with a short list
/// (less scroll than the header needs) it would stay half folded. This view:
///
///  * adds blank space at the end so there is always at least the fold
///    distance to scroll; only with fewer than [minItemsToFold] items that fit
///    on the screen it adds none (nothing to scroll, so the header stays);
///  * snaps to the folded or the expanded state when the scroll rests in
///    between, so it is never left half way;
///  * learns the fold distance from the header ([CollapsingFoldScope]).
///
/// While the finger drags nothing changes: the header still follows 1 to 1.
class CollapsingScrollView extends StatefulWidget {
  /// The `CollapsingHeader` sliver.
  final Widget header;

  /// The content slivers, below [header].
  final List<Widget> slivers;

  /// Items the list shows. Loading, error and empty states count as 0.
  final int itemCount;

  /// From this many items on the header always folds completely.
  final int minItemsToFold;

  final ScrollPhysics? physics;
  final ScrollController? controller;

  const CollapsingScrollView({
    super.key,
    required this.header,
    required this.slivers,
    required this.itemCount,
    this.minItemsToFold = 2,
    this.physics,
    this.controller,
  });

  @override
  State<CollapsingScrollView> createState() => _CollapsingScrollViewState();
}

class _CollapsingScrollViewState extends State<CollapsingScrollView> {
  static const Duration _snapDuration = Duration(milliseconds: 180);

  /// Tolerance (dp) to treat a position as already folded or expanded.
  static const double _snapTolerance = 0.5;

  /// Scroll distance the header needs to fold; 0 until it is measured.
  double _foldDistance = 0;

  void _onFoldDistance(double distance) {
    if (!mounted || (distance - _foldDistance).abs() < 0.01) return;
    setState(() => _foldDistance = distance);
  }

  /// Where to settle a scroll that rests at [pixels], or null to leave it.
  static double? _snapTarget(double pixels, double maxExtent, double fold) {
    if (fold <= 0 || maxExtent < fold - _snapTolerance) return null;
    if (pixels <= _snapTolerance || pixels >= fold - _snapTolerance) {
      return null;
    }
    return pixels >= fold / 2 ? math.min(fold, maxExtent) : 0;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollEndNotification ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final metrics = notification.metrics;
    if (_snapTarget(metrics.pixels, metrics.maxScrollExtent, _foldDistance) ==
        null) {
      return false;
    }
    final context = notification.context;
    final scrollable = context == null ? null : Scrollable.maybeOf(context);
    if (scrollable != null) _snapAfterFrame(scrollable);
    // Never consumed: a RefreshIndicator above also listens to the end.
    return false;
  }

  void _snapAfterFrame(ScrollableState scrollable) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollable.mounted) return;
      final position = scrollable.position;
      // A new drag started meanwhile: let the finger win.
      if (!position.hasPixels || position.isScrollingNotifier.value) return;
      final target = _snapTarget(
        position.pixels,
        position.maxScrollExtent,
        _foldDistance,
      );
      if (target == null) return;
      unawaited(
        position.animateTo(
          target,
          duration: _snapDuration,
          curve: Curves.easeOut,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CollapsingFoldScope(
      onFoldDistance: _onFoldDistance,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: CustomScrollView(
          controller: widget.controller,
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          slivers: [
            widget.header,
            ...widget.slivers,
            _FoldPadding(
              foldDistance: _foldDistance,
              alwaysFill: widget.itemCount >= widget.minItemsToFold,
            ),
          ],
        ),
      ),
    );
  }
}

/// Last sliver: blank space that makes the scroll extent at least the fold
/// distance (viewport + fold distance of content in total).
class _FoldPadding extends StatelessWidget {
  const _FoldPadding({required this.foldDistance, required this.alwaysFill});

  final double foldDistance;

  /// False: only fill when the content already overflows the viewport.
  final bool alwaysFill;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.viewportMainAxisExtent;
        final preceding = constraints.precedingScrollExtent;
        final fill = foldDistance > 0 && (alwaysFill || preceding > viewport);
        final height = fill
            ? math.max(0.0, viewport + foldDistance - preceding)
            : 0.0;
        return SliverToBoxAdapter(child: SizedBox(height: height));
      },
    );
  }
}
