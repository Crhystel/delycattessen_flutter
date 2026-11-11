import 'package:flutter/widgets.dart';

/// Lets a `CollapsingHeader` tell the scroll view that holds it how far it
/// folds (its full height minus the part that stays), so the scroll view can
/// guarantee that much scroll and snap the header when the finger lifts.
///
/// It is optional: a header with no scope above it behaves on its own.
class CollapsingFoldScope extends InheritedWidget {
  const CollapsingFoldScope({
    super.key,
    required this.onFoldDistance,
    required super.child,
  });

  /// Called with the scroll distance (dp) the header needs to fold completely.
  final ValueChanged<double> onFoldDistance;

  static CollapsingFoldScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CollapsingFoldScope>();

  // The callback is stable and only called, never read to build: no rebuilds.
  @override
  bool updateShouldNotify(CollapsingFoldScope oldWidget) => false;
}
