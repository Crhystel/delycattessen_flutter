import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import 'floating_bubbles.dart';

/// Common page frame: unified background, safe area and optional decorative
/// bubbles (use them only on Login and Home). [bubbleCorner] paints one
/// corner; [bubbleCorners] paints several (e.g. top and bottom as in Figma).
/// On tablets the body is centered and limited to [maxContentWidth] while the
/// bubbles stay in the screen corners.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final BubbleCorner? bubbleCorner;
  final List<BubbleCorner> bubbleCorners;
  final double maxContentWidth;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.bubbleCorner,
    this.bubbleCorners = const [],
    this.maxContentWidth = AppLayout.pageMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final corners = {...bubbleCorners, ?bubbleCorner};
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          for (final corner in corners)
            RepaintBoundary(child: FloatingBubbles(corner: corner)),
          SafeArea(
            child: ResponsiveCenter(maxWidth: maxContentWidth, child: body),
          ),
        ],
      ),
    );
  }
}
