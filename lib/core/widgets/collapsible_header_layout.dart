import 'package:flutter/material.dart';

/// Page layout where the top block hides while the user scrolls the list down
/// and comes back when scrolling up, so the list gets the whole screen.
///
/// [pinned] is always visible (e.g. the search field), [collapsible] folds away
/// with a short animation and [body] is the scrollable content. It only reacts
/// to the user's own drags (not to programmatic jumps) and only collapses when
/// the list would still be scrollable without the header, so the header can
/// never get stuck hidden.
class CollapsibleHeaderLayout extends StatefulWidget {
  final Widget? pinned;
  final Widget collapsible;
  final Widget body;

  const CollapsibleHeaderLayout({
    super.key,
    this.pinned,
    required this.collapsible,
    required this.body,
  });

  @override
  State<CollapsibleHeaderLayout> createState() =>
      _CollapsibleHeaderLayoutState();
}

class _CollapsibleHeaderLayoutState extends State<CollapsibleHeaderLayout> {
  /// Distance scrolled before the header starts to hide (avoids flicker).
  static const double _hideAfter = 24;
  static const Duration _duration = Duration(milliseconds: 200);

  final GlobalKey _collapsibleKey = GlobalKey();
  bool _collapsed = false;

  void _setCollapsed(bool value) {
    if (!mounted || _collapsed == value) return;
    setState(() => _collapsed = value);
  }

  /// True when the list still scrolls once the header is gone.
  bool _stillScrollable(ScrollMetrics metrics) {
    final headerHeight = _collapsibleKey.currentContext?.size?.height ?? 0;
    return metrics.maxScrollExtent > headerHeight;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final metrics = notification.metrics;
    if (metrics.pixels <= 0) {
      _setCollapsed(false);
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0 &&
          metrics.pixels > _hideAfter &&
          _stillScrollable(metrics)) {
        _setCollapsed(true);
      } else if (delta < 0) {
        _setCollapsed(false);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _duration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?widget.pinned,
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: _collapsed ? 0.0 : 1.0,
            duration: duration,
            curve: Curves.easeOut,
            child: ExcludeSemantics(
              excluding: _collapsed,
              child: KeyedSubtree(
                key: _collapsibleKey,
                child: widget.collapsible,
              ),
            ),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.body,
          ),
        ),
      ],
    );
  }
}
