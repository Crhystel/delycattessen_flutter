import 'package:flutter/material.dart';

/// Where [CollapsingHeader] keeps its always-visible part.
enum CollapsingHeaderKeep {
  /// The kept part is at the top and the rest folds up under it
  /// (e.g. search field, then title and filters).
  top,

  /// The kept part is at the bottom and the rest folds away above it
  /// (e.g. title and banner, then search field and days).
  bottom,
}

/// Header of a [CustomScrollView] that shrinks together with the scroll: it is
/// pinned to the top and folds the [collapsible] part away while the user
/// scrolls down, always leaving the [kept] part visible.
///
/// It moves 1 to 1 with the finger (its height is computed from the scroll
/// position, no timed animation), so the list never fights the header. It
/// only grows back when the list returns to its start. The sizes are measured
/// from the content (`minExtentPrototype` = only [kept], `maxExtentPrototype`
/// = everything), so it adapts to any text size without fixed heights.
class CollapsingHeader extends StatelessWidget {
  final Widget kept;
  final Widget collapsible;
  final CollapsingHeaderKeep keep;

  /// Opaque so the list that scrolls under the header does not show through.
  final Color backgroundColor;

  const CollapsingHeader({
    super.key,
    required this.kept,
    required this.collapsible,
    this.keep = CollapsingHeaderKeep.top,
    this.backgroundColor = Colors.white,
  });

  Widget get _full => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: keep == CollapsingHeaderKeep.top
        ? [kept, collapsible]
        : [collapsible, kept],
  );

  @override
  Widget build(BuildContext context) {
    final full = _full;
    return SliverResizingHeader(
      // The prototypes only measure; they are never painted, so they are also
      // hidden from the accessibility tree (no duplicated announcements).
      minExtentPrototype: ExcludeSemantics(child: kept),
      maxExtentPrototype: ExcludeSemantics(child: full),
      child: ColoredBox(
        color: backgroundColor,
        // Clipped (not squeezed): the content keeps its natural size and the
        // box only reveals the part that fits, so nothing overflows.
        child: ClipRect(
          child: OverflowBox(
            alignment: keep == CollapsingHeaderKeep.top
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: full,
          ),
        ),
      ),
    );
  }
}
