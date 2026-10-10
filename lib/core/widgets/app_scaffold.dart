import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'floating_bubbles.dart';

/// Common page frame: unified background, safe area and optional decorative
/// bubbles (use them only on Login and Home).
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final BubbleCorner? bubbleCorner;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.bubbleCorner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          if (bubbleCorner != null)
            RepaintBoundary(child: FloatingBubbles(corner: bubbleCorner!)),
          SafeArea(child: body),
        ],
      ),
    );
  }
}
