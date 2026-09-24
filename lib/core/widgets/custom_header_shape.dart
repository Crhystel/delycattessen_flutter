import 'package:flutter/material.dart';
import 'floating_bubbles.dart';

class CustomHeaderShape extends StatelessWidget {
  final double height;

  const CustomHeaderShape({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingBubbles(corner: BubbleCorner.topRight),
        ],
      ),
    );
  }
}
