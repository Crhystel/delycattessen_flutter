import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

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
///
/// Measuring needs the sliver to lay out two prototypes. The first frame uses
/// invisible copies of the real widgets; as soon as the real content reports
/// its size, the prototypes become plain boxes of that height, so the header is
/// built once (not three times) from then on.
class CollapsingHeader extends StatefulWidget {
  final Widget kept;
  final Widget collapsible;
  final CollapsingHeaderKeep keep;

  /// Optional part that folds away BELOW [kept] (e.g. category filters under
  /// the search field). When given, the column is [collapsible], [kept],
  /// [collapsibleBelow] and only [kept] stays visible once folded; [keep] is
  /// ignored.
  final Widget? collapsibleBelow;

  /// Drawn behind the content, clipped to the header, whenever the header is
  /// opaque (list scrolled). Pass the same decoration the page paints behind
  /// the header (the bubbles) so the opaque band does not cut it: the header
  /// then looks exactly like the page with only the kept part on top.
  final Widget? backdrop;

  /// Opaque so the list that scrolls under the header does not show through.
  final Color backgroundColor;

  /// With the list at its start the header lets the page behind it show (the
  /// decorative bubbles) and becomes opaque as soon as the list scrolls.
  final bool transparentAtTop;

  /// Blank space above everything, always visible (even folded). Screens drawn
  /// edge to edge pass the status bar / camera inset here so the pinned header
  /// never goes under it.
  final double topInset;

  const CollapsingHeader({
    super.key,
    required this.kept,
    required this.collapsible,
    this.keep = CollapsingHeaderKeep.top,
    this.collapsibleBelow,
    this.backdrop,
    this.backgroundColor = Colors.white,
    this.transparentAtTop = false,
    this.topInset = 0,
  });

  @override
  State<CollapsingHeader> createState() => _CollapsingHeaderState();
}

class _CollapsingHeaderState extends State<CollapsingHeader> {
  /// Natural heights reported by the real content; null until the first layout.
  double? _keptHeight;
  double? _fullHeight;

  /// Height of the part above [CollapsingHeader.kept] (middle mode only).
  double? _aboveHeight;

  void _onKeptSize(double height) {
    if (!mounted) return;
    if (_keptHeight != null && (height - _keptHeight!).abs() < 0.01) return;
    setState(() => _keptHeight = height);
  }

  void _onFullSize(double height) {
    if (!mounted) return;
    if (_fullHeight != null && (height - _fullHeight!).abs() < 0.01) return;
    setState(() => _fullHeight = height);
  }

  void _onAboveSize(double height) {
    if (!mounted) return;
    if (_aboveHeight != null && (height - _aboveHeight!).abs() < 0.01) return;
    setState(() => _aboveHeight = height);
  }

  bool get _middle => widget.collapsibleBelow != null;

  Widget _full(Widget kept, {Widget? above}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _middle
        ? [above ?? widget.collapsible, kept, widget.collapsibleBelow!]
        : widget.keep == CollapsingHeaderKeep.top
        ? [kept, widget.collapsible]
        : [widget.collapsible, kept],
  );

  Widget _withInset(Widget child) => widget.topInset > 0
      ? Padding(
          padding: EdgeInsets.only(top: widget.topInset),
          child: child,
        )
      : child;

  @override
  Widget build(BuildContext context) {
    final keptHeight = _keptHeight;
    final fullHeight = _fullHeight;
    final measured = keptHeight != null && fullHeight != null;

    // The real content, built once. Clipped (not squeezed): it keeps its
    // natural size and the box only reveals the part that fits, so nothing
    // overflows.
    final realContent = _SizeReporter(
      onSize: _onFullSize,
      child: _full(
        _SizeReporter(onSize: _onKeptSize, child: widget.kept),
        above: _middle
            ? _SizeReporter(onSize: _onAboveSize, child: widget.collapsible)
            : null,
      ),
    );
    final content = _middle
        ? _buildMiddleContent(realContent, keptHeight, fullHeight)
        : ClipRect(
            child: OverflowBox(
              alignment: widget.keep == CollapsingHeaderKeep.top
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: realContent,
            ),
          );

    final position = widget.transparentAtTop
        ? Scrollable.maybeOf(context)?.position
        : null;
    final painted = position == null
        ? _paint(true, _withInset(content))
        : ListenableBuilder(
            listenable: position,
            child: _withInset(content),
            builder: (_, child) => _paint(position.pixels > 0, child!),
          );

    // The prototypes only measure; they are never painted, so they are also
    // hidden from the accessibility tree (no duplicated announcements).
    return SliverResizingHeader(
      minExtentPrototype: _withInset(
        measured
            ? SizedBox(height: keptHeight)
            : ExcludeSemantics(child: widget.kept),
      ),
      maxExtentPrototype: _withInset(
        measured
            ? SizedBox(height: fullHeight)
            : ExcludeSemantics(child: _full(widget.kept)),
      ),
      child: painted,
    );
  }

  /// Opaque (or transparent) background of the header, with the [backdrop]
  /// painted on it while opaque.
  Widget _paint(bool opaque, Widget child) {
    final backdrop = widget.backdrop;
    if (!opaque || backdrop == null) {
      return ColoredBox(
        color: opaque ? widget.backgroundColor : Colors.transparent,
        child: child,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ClipRect(
            child: ColoredBox(color: widget.backgroundColor, child: backdrop),
          ),
        ),
        child,
      ],
    );
  }

  /// Content of the three-zone mode: the part above slides up and the part
  /// below is cut off as the header folds, so only [CollapsingHeader.kept]
  /// remains. With the box at height `h` between the kept and the full height,
  /// the content is shifted up by `above * t`, t going from 0 (full) to 1
  /// (folded): the kept part ends exactly at the top of the box.
  Widget _buildMiddleContent(
    Widget realContent,
    double? keptHeight,
    double? fullHeight,
  ) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final above = _aboveHeight;
          var shift = 0.0;
          if (keptHeight != null && fullHeight != null && above != null) {
            final span = fullHeight - keptHeight;
            final t = span <= 0
                ? 1.0
                : ((fullHeight - constraints.maxHeight) / span).clamp(0.0, 1.0);
            shift = above * t;
          }
          return OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(0, -shift),
              child: realContent,
            ),
          );
        },
      ),
    );
  }
}

/// Reports the height its child takes when laid out, after the frame, so the
/// parent can react without calling `setState` during layout.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<double> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSizeReporter renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<double> onSize;
  double? _lastReported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (_lastReported != null && (height - _lastReported!).abs() < 0.01) {
      return;
    }
    _lastReported = height;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(height);
    });
  }
}
