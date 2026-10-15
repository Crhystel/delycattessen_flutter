import 'package:flutter/material.dart';

import 'floating_bubbles.dart';

/// Common page frame: unified background, safe area and optional decorative
/// bubbles (use them only on Login and Home). [bubbleCorner] paints one
/// corner; [bubbleCorners] paints several (e.g. top and bottom as in Figma).
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final BubbleCorner? bubbleCorner;
  final List<BubbleCorner> bubbleCorners;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.bubbleCorner,
    this.bubbleCorners = const [],
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
          SafeArea(child: body),
        ],
      ),
    );
  }
}
