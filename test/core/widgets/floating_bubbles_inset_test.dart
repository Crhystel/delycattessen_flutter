import 'package:delycattessen_flutter/core/widgets/floating_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bottom of the lowest visible bubble pixel is hard to read from the tree, so
/// the bubbles' own box is measured: with a system navigation bar of [inset] dp
/// the bottom bubbles are lifted by that much (and clipped there).
Future<double> _boxBottom(
  WidgetTester tester, {
  required BubbleCorner corner,
  required double inset,
  bool design = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewPadding: EdgeInsets.only(bottom: inset),
          padding: EdgeInsets.only(bottom: inset),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: FloatingBubbles(corner: corner, design: design),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  // The clip around the bubbles ends where the lifted box ends.
  final clip = find.descendant(
    of: find.byType(FloatingBubbles),
    matching: find.byType(ClipRect),
  );
  if (clip.evaluate().isEmpty) {
    return tester.getSize(find.byType(FloatingBubbles)).height;
  }
  return tester.getRect(clip.first).bottom;
}

void main() {
  for (final design in [true, false]) {
    testWidgets('bottom bubbles stop above the navigation bar '
        '(${design ? "design" : "animated"})', (tester) async {
      final without = await _boxBottom(
        tester,
        corner: BubbleCorner.homeBottomRight,
        inset: 0,
        design: design,
      );
      final withBar = await _boxBottom(
        tester,
        corner: BubbleCorner.homeBottomRight,
        inset: 48,
        design: design,
      );

      expect(without, 844);
      expect(withBar, 844 - 48);
    });
  }

  testWidgets('top bubbles are not moved by the bottom inset', (tester) async {
    final bottom = await _boxBottom(
      tester,
      corner: BubbleCorner.topRight,
      inset: 48,
    );

    // No clip box was added: the layer keeps the whole screen.
    expect(bottom, 844);
  });
}
